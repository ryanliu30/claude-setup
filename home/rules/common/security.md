# Security

## Mandatory Checks Before Any Commit

- [ ] No hardcoded secrets (API keys, passwords, tokens, SSH keys)
- [ ] All user inputs validated at entry points
- [ ] No `eval()`/`exec()` on untrusted input
- [ ] No `pickle.load()` from untrusted sources; use `safetensors`, `numpy.load`, or `torch.load` with `weights_only=True`
- [ ] Parameterized queries for any SQL, never string concatenation
- [ ] Error messages don't leak sensitive data (stack traces, file paths, internal state)

## Secret Management

- Use environment variables or a secrets manager (`python-dotenv`, `vault`, AWS Secrets Manager).
- Validate required secrets are present at startup, not lazily.
- Rotate any secret that may have been exposed (committed, logged, transmitted).
- Add secrets files to `.gitignore` immediately when creating them.

## ML-Specific Security

- Model weights loaded from external sources can execute arbitrary code via `pickle`; always use `torch.load(..., weights_only=True)` for untrusted checkpoints.
- Do not log raw user inputs or model inputs that may contain PII.
- Gradient checkpointing files and intermediate activations saved to disk should not be committed.

## If a Security Issue Is Found

1. STOP immediately.
2. Do not commit the affected code.
3. Rotate any exposed secrets.
4. Fix the issue, then review the surrounding code for similar patterns.
