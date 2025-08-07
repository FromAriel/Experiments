// ###############################################################
// VidCam/src/overlay.rs
// Key Functions    • run_overlay() – launch interactive window
// Key Structs      • OverlayApp – egui application wrapper
// Dependencies     • eframe, tokio, image
// Last Major Rev   • 2024-05-?? – egui-based implementation
// ###############################################################

use crate::config::{save_config_async, Config};
use image::DynamicImage;
use std::sync::{Arc, Mutex};
use tokio::sync::broadcast;

use eframe::{egui, NativeOptions};
use egui::{Color32, Pos2, Vec2};

/// Run the overlay window until closed.
pub fn run_overlay(
    cfg: Arc<Mutex<Config>>,
    frame_rx: broadcast::Receiver<DynamicImage>,
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
    frames: broadcast::Receiver<DynamicImage>,
    texture: Option<egui::TextureHandle>,
}

impl OverlayApp {
    fn new(
        _cc: &eframe::CreationContext<'_>,
        cfg: Arc<Mutex<Config>>,
        frames: broadcast::Receiver<DynamicImage>,
    ) -> Self {
        Self {
            cfg,
            frames,
            texture: None,
        }
    }

    fn update_texture(&mut self, ctx: &egui::Context) {
        while let Ok(frame) = self.frames.try_recv() {
            let size = [frame.width() as usize, frame.height() as usize];
            let rgba = frame.to_rgba8();
            let img = egui::ColorImage::from_rgba_unmultiplied(size, &rgba);
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
                    ui.painter()
                        .rect_filled(rect, 4.0, Color32::from_rgb(0, 128, 255));
                    let response = response.on_hover_cursor(cursor);
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
                        save_config_async(cfg.clone());
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

        egui::CentralPanel::default().show(ctx, |ui| {
            ui.set_opacity(if hovered {1.0} else {base});
            if let Some(ref tex) = self.texture { ui.image(tex); }
        });

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
