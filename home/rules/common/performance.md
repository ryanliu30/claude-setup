# Performance

Profile before optimizing. Measure, then fix.

## Profiling Tools

| Use case | Tool |
|----------|------|
| Python CPU profiling | `py-spy top --pid <pid>` or `python -m cProfile -o out.prof script.py` |
| Line-level profiling | `line_profiler` (`@profile` decorator) |
| GPU profiling | `torch.profiler.profile(...)` |
| Memory profiling | `memory_profiler`, `tracemalloc` |

## Python

- Vectorize over arrays >1K elements, no Python loops.
- Use `numpy` broadcasting instead of explicit loops.
- Prefer list comprehensions over `map`/`filter` for readability; both are fast.
- Avoid repeated string concatenation in loops, use `"".join(parts)`.
- Use generators for large sequences that are consumed once.

## PyTorch / GPU

- Use `torch.compile()` (PyTorch 2.x) for production training throughput.
- Always call `model.eval()` and `torch.no_grad()` during inference.
- Pin memory (`pin_memory=True` in `DataLoader`) for faster CPU→GPU transfers.
- Use `torch.cuda.amp.autocast()` for mixed-precision training.
- Profile with `torch.profiler` before assuming a bottleneck is in the model.

## Large Datasets

- Use memory-mapped files (`np.memmap`, HuggingFace `datasets`) for datasets that don't fit in RAM.
- Stream data with `IterableDataset` when random access is not required.
- Pre-compute and cache expensive features (embeddings, tokenizations) rather than recomputing each epoch.

## C Extensions (Cython)

- Minimize Python↔C boundary crossings, batch work in C, return results once.
- Use typed memoryviews (`double[::1]`) for arrays.
- Disable bounds/wrap checking (`boundscheck=False`, `wraparound=False`) only after correctness is verified.
- Use `prange` from `cython.parallel` for CPU parallelism.

## Context Window (Claude)

- Use extended thinking (Option+T) for complex architectural decisions.
- Keep context lean, summarize long outputs rather than including raw tool results in prompts.
- Prefer Haiku for lightweight, high-frequency agents; Sonnet for main development; Opus for deep reasoning tasks.
