## 3. Resource Catalogue and Suggestions

Resources are grouped by relevance (**1 = highly relevant; 5 = tangential but potentially useful**). All links below are verified and actionable.

### Level 1 – Foundational resources

1. **LLM as OS, Agents as Apps: Envisioning AIOS, Agents and the AIOS‑Agent Ecosystem (Ge et al., 2023).** [arXiv:2312.03815](https://arxiv.org/abs/2312.03815) • [HTML v2](https://arxiv.org/html/2312.03815v2). Introduces LLM‑as‑OS, mapping kernel/memory/storage/tools/prompts; proposes research directions in resource management, communication protocols and security.
2. **AI‑oriented grammar & SimPy (Sun et al., 2024).** [arXiv:2404.16333](https://arxiv.org/abs/2404.16333) • [HTML v2](https://arxiv.org/html/2404.16333v2). Demonstrates how modifying Python’s grammar to minimize tokens reduces inference cost and can improve model performance.
3. **Swift for TensorFlow (Saeta et al., 2021).** [MLSys 2021 PDF](https://proceedings.mlsys.org/paper_files/paper/2021/file/1d781258d409a6efc66cd1aa14a1681c-Paper.pdf) • [arXiv:2102.13243](https://arxiv.org/abs/2102.13243). Describes language‑integrated automatic differentiation and mutable value semantics in Swift.
4. **Mojo: AI‑optimized programming language.** [Official docs (Modular)](https://docs.modular.com/mojo/) • [Overview](https://www.modular.com/mojo). Shows how a new language can remain Python‑compatible while targeting AI workloads (via MLIR, ownership, etc.).
5. **FAISISS Design Document (Ariel).** Repo root: [https://github.com/FromAriel/FAISISS](https://github.com/FromAriel/FAISISS) (commit‑pinned deep links provided in Section 2).

### Level 2 – Design and implementation guides

* **Reactive and event‑driven programming.** Actor model, message‑passing, async/await semantics for handling AI calls/tools. See: [The Reactive Manifesto](https://www.reactivemanifesto.org/) • [Akka Typed docs](https://doc.akka.io/docs/akka/current/typed/index.html) • [Python `asyncio` docs](https://docs.python.org/3/library/asyncio.html).
* **Domain‑specific language (DSL) construction.** Markus Völter’s *DSL Engineering* (free online): [dslbook.org](https://www.dslbook.org/). **Additional tooling:** [JetBrains MPS](https://www.jetbrains.com/mps/) • [Eclipse Xtext](https://www.eclipse.org/Xtext/).
* **Retrieval‑augmented generation (RAG).** Core paper: Lewis et al., 2020 — [arXiv:2005.11401](https://arxiv.org/abs/2005.11401). Frameworks: [LangChain docs](https://python.langchain.com/) • [LlamaIndex docs](https://docs.llamaindex.ai/).
* **Symbolic–neural integration.** Examples and surveys: **DeepProbLog** — [arXiv:1805.10872](https://arxiv.org/abs/1805.10872) • **Logic Tensor Networks** — [arXiv:1606.04422](https://arxiv.org/abs/1606.04422) • **A Roadmap for Neuro‑Symbolic AI** — [arXiv:2102.11503](https://arxiv.org/abs/2102.11503).
* **Safe AI and content moderation.** **OWASP Top 10 for LLM Applications** — [project page](https://owasp.org/www-project-top-10-for-large-language-model-applications/) • **NIST AI RMF 1.0** — [framework site](https://www.nist.gov/itl/ai-risk-management-framework). **Further reading:** [Anthropic Red Teaming Framework](https://www.anthropic.com/red-teaming-framework).

### Level 3 – Supporting technologies

* **Differentiable programming frameworks.** [JAX docs](https://jax.readthedocs.io/en/stable/) • [PyTorch `torch.compile` docs](https://pytorch.org/docs/stable/generated/torch.compile.html) • [Zygote.jl docs](https://fluxml.ai/Zygote.jl/latest/).
* **Automatic program synthesis & code LLM benchmarks.** [HumanEval (OpenAI) GitHub](https://github.com/openai/human-eval) • [Code Llama (Meta) GitHub](https://github.com/facebookresearch/codellama) • **AlphaCode 2 Technical Report** — [PDF](https://storage.googleapis.com/deepmind-media/AlphaCode2/AlphaCode2_Tech_Report.pdf).
* **LLM prompt engineering best practices.** [OpenAI Cookbook (GitHub)](https://github.com/openai/openai-cookbook) • [Cookbook site](https://cookbook.openai.com/).
* **Knowledge‑graph integration.** **GraphRAG** — [Microsoft GitHub](https://github.com/microsoft/graphrag) • Survey: **Knowledge‑Enhanced LLMs** — [arXiv:2301.07543](https://arxiv.org/abs/2301.07543). **Platforms:** [Neo4j Knowledge Graph](https://neo4j.com/use-cases/knowledge-graph/) • [Amazon Neptune](https://aws.amazon.com/neptune/).
* **Agent frameworks.** [AutoGen (Microsoft) GitHub](https://github.com/microsoft/autogen) • [AutoGPT GitHub](https://github.com/Significant-Gravitas/AutoGPT) • [LangChain Agents](https://python.langchain.com/docs/modules/agents/).

### Level 4 – Cross‑disciplinary insights

* **Cognitive architectures.** [ACT‑R official](https://act-r.psy.cmu.edu/) • [Soar official](https://soar.eecs.umich.edu/).
* **Game AI and simulation frameworks.** [Unity ML‑Agents GitHub](https://github.com/Unity-Technologies/ml-agents).
* **Compiler construction and optimization.** [MLIR (LLVM) site](https://mlir.llvm.org/) • [LLVM project](https://llvm.org/).
* **Human‑computer interaction (HCI).** General NL‑programming/HCI references to guide interface design; pair with the **Reactive Manifesto** above for interaction patterns. **Resources:** [Interaction Design Foundation](https://www.interaction-design.org/) • [Nielsen Norman Group](https://www.nngroup.com/).
* **Ethics and policy research.** [NIST AI RMF 1.0](https://www.nist.gov/itl/ai-risk-management-framework) • [ACM Code of Ethics](https://www.acm.org/code-of-ethics).

### Level 5 – Tangential but potentially useful

* **Quantum computing languages.** [Q# docs (Microsoft Learn)](https://learn.microsoft.com/azure/quantum/qsharp-overview) • [Qiskit docs](https://qiskit.org/learn/intro-to-quantum-computing/what-is-quantum-computing).
* **Bio‑inspired computing.** [Intel Lava (neuromorphic framework)](https://lava-nc.org/).
* **Interactive storytelling research.** Overview texts on narrative theory and procedural generation; e.g., the PCG in games literature (various sources). **Tools:** [Ink](https://www.inklestudios.com/ink/) • [Twine](https://twinery.org/).
* **Multi‑modal AI models.** **CLIP** — [arXiv:2103.00020](https://arxiv.org/abs/2103.00020) • **Stable Diffusion** — [CompVis GitHub](https://github.com/CompVis/stable-diffusion).
* **General PL theory.** *Types and Programming Languages* — [book site](https://www.cis.upenn.edu/~bcpierce/tapl/) • *Software Foundations* — [online textbook](https://softwarefoundations.cis.upenn.edu/).

---
