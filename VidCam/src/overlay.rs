// ###############################################################
// VidCam/src/overlay.rs
// Key Functions    • run_overlay() – launch interactive window
// Key Structs      • OverlayApp – egui application wrapper
// Dependencies     • eframe, tokio, image
// Last Major Rev   • 2024-05-?? – egui-based implementation
// ###############################################################

use crate::config::{save_config_async, Config};
use crate::frame::RawFrame;
use std::sync::{Arc, Mutex};
use tokio::sync::broadcast;
use std::time::{Duration, Instant};

use eframe::{egui, NativeOptions};
use egui::{Color32, Pos2, Vec2};

/// Run the overlay window until closed.
pub fn run_overlay(
    cfg: Arc<Mutex<Config>>,
    frame_rx: broadcast::Receiver<RawFrame>,
) -> eframe::Result<()> {
    let (w, h, pos) = {
        let c = cfg.lock().unwrap();
        (
            c.window_size.0 as f32,
            c.window_size.1 as f32,
            Pos2::new(c.window_position.0 as f32, c.window_position.1 as f32),
        )
    };
    let viewport = egui::ViewportBuilder::default()
        .with_inner_size(Vec2::new(w, h))
        .with_position(pos)
        .with_always_on_top()
        .with_decorations(false)
        .with_transparent(true);
    let options = NativeOptions {
        viewport,
        ..Default::default()
    };
    eframe::run_native(
        "VidCam",
        options,
        Box::new(move |cc| -> Result<_, Box<dyn std::error::Error + Send + Sync>> {
            Ok(Box::new(OverlayApp::new(cc, cfg.clone(), frame_rx)) as Box<dyn eframe::App>)
        }),
    )
}

struct OverlayApp {
    cfg: Arc<Mutex<Config>>,
    frames: broadcast::Receiver<RawFrame>,
    texture: Option<egui::TextureHandle>,
    opacity: f32,
    last_save: Instant,
    last_fade: Instant,
}

impl OverlayApp {
    fn new(
        _cc: &eframe::CreationContext<'_>,
        cfg: Arc<Mutex<Config>>,
        frames: broadcast::Receiver<RawFrame>,
    ) -> Self {
        Self {
            cfg: cfg.clone(),
            frames,
            texture: None,
            opacity: cfg.lock().unwrap().base_opacity,
            last_save: Instant::now() - Duration::from_secs(1),
            last_fade: Instant::now(),
        }
    }

    fn update_texture(&mut self, ctx: &egui::Context) {
        while let Ok(frame) = self.frames.try_recv() {
            let size = [frame.width as usize, frame.height as usize];
            let img = egui::ColorImage::from_rgba_unmultiplied(size, &frame.data);
            self.texture = Some(ctx.load_texture("rtsp", img, Default::default()));
        }
    }

    fn resize_handles(&mut self, ctx: &egui::Context) {
        let size = 16.0;
        let corners = [
            ("tl", Pos2::new(0.0, 0.0), egui::CursorIcon::ResizeNwSe),
            ("tr", Pos2::new(ctx.screen_rect().width() - size, 0.0), egui::CursorIcon::ResizeNeSw),
            (
                "bl",
                Pos2::new(0.0, ctx.screen_rect().height() - size),
                egui::CursorIcon::ResizeNeSw,
            ),
            (
                "br",
                Pos2::new(
                    ctx.screen_rect().width() - size,
                    ctx.screen_rect().height() - size,
                ),
                egui::CursorIcon::ResizeNwSe,
            ),
        ];
        for (id, pos, cursor) in corners {
            egui::Area::new(id.into())
                .fixed_pos(pos)
                .show(ctx, |ui| {
                    let (rect, response) = ui.allocate_exact_size(Vec2::splat(size), egui::Sense::drag());
                    let response = response.on_hover_cursor(cursor);
                    let center = rect.center();
                    let radius = size / 2.0;
                    let color = Color32::from_rgb(0, 128, 255);
                    ui.painter().circle_filled(center, radius, color);
                    if response.hovered() {
                        ui.painter().circle_stroke(center, radius + 2.0, (1.0, Color32::LIGHT_BLUE));
                    }
                    if response.dragged() {
                        let delta = response.drag_delta();
                        let mut cfg = self.cfg.lock().unwrap();
                        let mut new_pos = Pos2::new(
                            cfg.window_position.0 as f32,
                            cfg.window_position.1 as f32,
                        );
                        let mut new_size = Vec2::new(
                            cfg.window_size.0 as f32,
                            cfg.window_size.1 as f32,
                        );
                        match id {
                            "tl" => {
                                new_pos.x += delta.x;
                                new_pos.y += delta.y;
                                new_size.x -= delta.x;
                                new_size.y -= delta.y;
                            }
                            "tr" => {
                                new_pos.y += delta.y;
                                new_size.x += delta.x;
                                new_size.y -= delta.y;
                            }
                            "bl" => {
                                new_pos.x += delta.x;
                                new_size.x -= delta.x;
                                new_size.y += delta.y;
                            }
                            _ => {
                                new_size.x += delta.x;
                                new_size.y += delta.y;
                            }
                        }
                        cfg.window_position = (new_pos.x as i32, new_pos.y as i32);
                        cfg.window_size = (
                            new_size.x.max(50.0) as u32,
                            new_size.y.max(50.0) as u32,
                        );
                        ctx.send_viewport_cmd(egui::ViewportCommand::InnerSize(new_size));
                        ctx.send_viewport_cmd(egui::ViewportCommand::OuterPosition(new_pos));
                        let now = Instant::now();
                        if now.duration_since(self.last_save) > Duration::from_secs(1) {
                            save_config_async(cfg.clone());
                            self.last_save = now;
                        }
                    }
                });
        }
    }
}

impl eframe::App for OverlayApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        ctx.request_repaint();
        self.update_texture(ctx);

        let hovered = ctx.input(|i| i.pointer.hover_pos().is_some());
        let base = { self.cfg.lock().unwrap().base_opacity };

        let target = if hovered { 1.0 } else { base };
        let now = Instant::now();
        let dt = (now - self.last_fade).as_secs_f32();
        self.last_fade = now;
        let t = (dt / 0.15).min(1.0);
        self.opacity += (target - self.opacity) * t;

        egui::CentralPanel::default().show(ctx, |ui| {
            ui.set_opacity(self.opacity);
            if let Some(ref tex) = self.texture {
                ui.image(tex);
            }
        });

        #[cfg(target_os = "windows")]
        ctx.send_viewport_cmd(egui::ViewportCommand::MousePassthrough(!hovered));

        // Persist geometry if changed
        let info = ctx.input(|i| i.viewport().clone());
        if let Some(rect) = info.outer_rect {
            let mut cfg = self.cfg.lock().unwrap();
            let pos = (rect.left().round() as i32, rect.top().round() as i32);
            let size = (rect.width().round() as u32, rect.height().round() as u32);
            if cfg.window_position != pos || cfg.window_size != size {
                cfg.window_position = pos;
                cfg.window_size = size;
                let now = Instant::now();
                if now.duration_since(self.last_save) > Duration::from_secs(1) {
                    save_config_async(cfg.clone());
                    self.last_save = now;
                }
            }
        }

        if hovered {
            egui::TopBottomPanel::bottom("opacity").show(ctx, |ui| {
                let mut cfg = self.cfg.lock().unwrap();
                let old = cfg.base_opacity;
                ui.add(egui::Slider::new(&mut cfg.base_opacity, 0.0..=0.1).text("Opacity"));
                if (cfg.base_opacity - old).abs() > f32::EPSILON {
                    save_config_async(cfg.clone());
                }
            });
            self.resize_handles(ctx);
        }
    }
}

pub fn run_overlay_headless_once(cfg: Arc<Mutex<Config>>, modify: impl FnOnce(&egui::Context) + Send + 'static) {
    use egui::{Pos2, Vec2};
    use eframe::NativeOptions;
    let (w, h, pos) = {
        let c = cfg.lock().unwrap();
        (c.window_size.0 as f32, c.window_size.1 as f32, Pos2::new(c.window_position.0 as f32, c.window_position.1 as f32))
    };
    let viewport = egui::ViewportBuilder::default()
        .with_inner_size(Vec2::new(w, h))
        .with_position(pos)
        .with_decorations(false)
        .with_transparent(true);
    let options = NativeOptions {
        run_and_return: true,
        viewport,
        event_loop_builder: Some(Box::new(|b| {
            #[cfg(target_os = "linux")]
            {
                use winit::platform::x11::EventLoopBuilderExtX11;
                use winit::platform::wayland::EventLoopBuilderExtWayland;
                EventLoopBuilderExtX11::with_any_thread(b, true);
                EventLoopBuilderExtWayland::with_any_thread(b, true);
            }
            #[cfg(target_os = "windows")]
            {
                use winit::platform::windows::EventLoopBuilderExtWindows;
                b.with_any_thread(true);
            }
        })),
        ..Default::default()
    };
    let (_tx, rx) = broadcast::channel(1);
    eframe::run_native("test", options, Box::new(move |cc| {
        modify(&cc.egui_ctx);
        Ok(Box::new(OverlayApp::new(cc, cfg.clone(), rx)) as Box<dyn eframe::App>)
    })).unwrap();
}
