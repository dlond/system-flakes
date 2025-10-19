# Python + JAX ML Environment

Machine learning and quantitative research environment with JAX and LaTeX support.

## Usage

```bash
# Initialize environment
nix flake init -t github:dlond/system-flakes#python-jax
nix develop

# Install JAX and dependencies
uv pip install jax jaxlib
uv pip install optax flax equinox
uv pip install jupyterlab matplotlib

# Start Jupyter Lab
uv run jupyter lab

# Run Python with JAX
python
>>> import jax
>>> import jax.numpy as jnp
>>> from jax import grad, jit, vmap
```

## JAX Example: Option Pricing with Autodiff

```python
import jax
import jax.numpy as jnp
from jax import grad, jit, vmap
import matplotlib.pyplot as plt

@jit
def black_scholes_call(S, K, r, sigma, T):
    """European call option price using Black-Scholes"""
    d1 = (jnp.log(S/K) + (r + sigma**2/2)*T) / (sigma*jnp.sqrt(T))
    d2 = d1 - sigma*jnp.sqrt(T)

    N = jax.scipy.stats.norm.cdf
    call_price = S*N(d1) - K*jnp.exp(-r*T)*N(d2)
    return call_price

# Automatic differentiation for Greeks
delta = jit(grad(black_scholes_call, argnums=0))  # ∂V/∂S
vega = jit(grad(black_scholes_call, argnums=3))   # ∂V/∂σ
theta = jit(grad(black_scholes_call, argnums=4))  # ∂V/∂T

# Vectorized pricing for portfolio
portfolio_pricer = vmap(black_scholes_call, in_axes=(0, 0, None, 0, 0))

# Example portfolio
spots = jnp.array([100., 105., 95., 110., 90.])
strikes = jnp.array([100., 100., 100., 105., 95.])
vols = jnp.array([0.2, 0.25, 0.15, 0.3, 0.18])
times = jnp.array([0.25, 0.5, 0.75, 1.0, 0.33])

prices = portfolio_pricer(spots, strikes, 0.05, vols, times)
print(f"Portfolio prices: {prices}")
```

## Machine Learning Example: Neural Network from Scratch

```python
import jax
import jax.numpy as jnp
from jax import random, grad, jit, vmap
import optax

def init_mlp_params(layer_sizes, key):
    """Initialize MLP parameters"""
    params = []
    for in_size, out_size in zip(layer_sizes[:-1], layer_sizes[1:]):
        key, subkey = random.split(key)
        W = random.normal(subkey, (in_size, out_size)) * jnp.sqrt(2.0 / in_size)
        b = jnp.zeros(out_size)
        params.append((W, b))
    return params

@jit
def mlp_forward(params, x):
    """Forward pass through MLP"""
    for W, b in params[:-1]:
        x = jax.nn.relu(x @ W + b)
    W, b = params[-1]
    return x @ W + b

@jit
def loss_fn(params, x_batch, y_batch):
    """MSE loss function"""
    predictions = vmap(lambda x: mlp_forward(params, x))(x_batch)
    return jnp.mean((predictions - y_batch) ** 2)

# Training loop with Optax
optimizer = optax.adam(learning_rate=1e-3)
opt_state = optimizer.init(params)

@jit
def update_step(params, opt_state, x_batch, y_batch):
    loss, grads = jax.value_and_grad(loss_fn)(params, x_batch, y_batch)
    updates, opt_state = optimizer.update(grads, opt_state)
    params = optax.apply_updates(params, updates)
    return params, opt_state, loss
```

## LaTeX Example: Research Paper Template

```latex
\documentclass{article}
\usepackage{amsmath, amsthm, amssymb}
\usepackage{algorithm2e}
\usepackage{pgfplots}

\title{Quantitative Research with JAX}
\author{Your Name}

\begin{document}
\maketitle

\section{Introduction}
JAX enables differentiable programming for scientific computing...

\section{Methodology}

\subsection{Automatic Differentiation}
The key advantage of JAX is its ability to automatically compute derivatives:

\begin{equation}
\nabla_\theta \mathcal{L}(\theta) = \frac{\partial}{\partial \theta}
\sum_{i=1}^{N} \ell(f_\theta(x_i), y_i)
\end{equation}

\subsection{Vectorization}
JAX's \texttt{vmap} transformation enables efficient batched computations:

\begin{algorithm}[H]
\SetAlgoLined
\KwIn{Parameters $\theta$, Data $\{x_i, y_i\}_{i=1}^N$}
\KwOut{Loss value and gradients}
$\mathcal{L} \leftarrow$ \texttt{vmap}($\ell \circ f_\theta$)($X$, $Y$)\;
$\nabla_\theta \mathcal{L} \leftarrow$ \texttt{grad}($\mathcal{L}$)($\theta$)\;
\Return{$\mathcal{L}$, $\nabla_\theta \mathcal{L}$}
\caption{Vectorized Gradient Computation}
\end{algorithm}

\end{document}
```

Compile with:
```bash
pdflatex research_paper.tex
```

## JAX Learning Path

### Week 1: Functional Fundamentals
- Pure functions and immutability
- JAX transformations: `grad`, `jit`, `vmap`, `pmap`
- Pytrees and tree operations

### Week 2: Building from Scratch
- Neural networks without frameworks
- Custom optimizers with Optax
- Automatic differentiation patterns

### Week 3: Performance Optimization
- JIT compilation strategies
- Vectorization with vmap
- Memory efficiency techniques

### Week 4: Applications
- Scientific computing
- Machine learning models
- Optimization problems
- Numerical simulations

## Project Ideas

1. **Differentiable Physics Simulator**
   - Implement physical systems in JAX
   - Optimize parameters with `grad`
   - Visualize with matplotlib

2. **Custom Deep Learning Framework**
   - Build layers and activations
   - Implement training loops
   - Add regularization techniques

3. **Optimization Library**
   - Implement optimization algorithms
   - Benchmark performance
   - Compare with scipy.optimize

## Resources

- [JAX Documentation](https://jax.readthedocs.io/)
- [JAX Tutorial](https://jax.readthedocs.io/en/latest/notebooks/quickstart.html)
- [Equinox for Neural Networks](https://docs.kidger.site/equinox/)
- [Optax for Optimization](https://optax.readthedocs.io/)
- [LaTeX for Mathematical Writing](https://en.wikibooks.org/wiki/LaTeX/Mathematics)