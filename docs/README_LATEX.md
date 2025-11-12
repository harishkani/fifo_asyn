# LaTeX Documentation Guide

This directory contains comprehensive LaTeX documentation for the asynchronous FIFO design.

## Files

### 1. FIFO_TUTORIAL.tex
**Complete Tutorial (30+ pages)**
- Full explanation from first principles
- Mathematical foundations
- Circuit diagrams
- Code listings
- Verification strategies

### 2. FIFO_EQUATIONS.tex
**Quick Reference Sheet (2 pages, landscape)**
- Key equations
- Design rules
- Common pitfalls
- Quick verification checklist

### 3. FIFO_TUTORIAL_COMPLETE.md
**Markdown Version**
- Complete tutorial in Markdown
- Same content as LaTeX version
- Easy to read on GitHub

## Compiling LaTeX Documents

### Prerequisites

Install LaTeX distribution:
```bash
# Ubuntu/Debian
sudo apt-get install texlive-full

# macOS
brew install mactex

# Windows
# Download and install MiKTeX or TeX Live
```

### Compilation Commands

**For the main tutorial:**
```bash
cd docs
pdflatex FIFO_TUTORIAL.tex
pdflatex FIFO_TUTORIAL.tex  # Run twice for references
```

**For the quick reference:**
```bash
cd docs
pdflatex FIFO_EQUATIONS.tex
```

**Using latexmk (recommended):**
```bash
latexmk -pdf FIFO_TUTORIAL.tex
latexmk -pdf FIFO_EQUATIONS.tex
```

### Output Files

After compilation:
- `FIFO_TUTORIAL.pdf` - Complete tutorial document
- `FIFO_EQUATIONS.pdf` - Quick reference sheet

## Document Structure

### FIFO_TUTORIAL.tex Contents

1. **Introduction to FIFOs**
   - Basic concepts
   - Why we need FIFOs
   - Synchronous vs Asynchronous

2. **Clock Domain Crossing**
   - Metastability problem
   - Binary counter issues
   - CDC dangers

3. **Gray Code Solution**
   - Definition and theory
   - Conversion algorithms
   - Mathematical proofs

4. **Pointer Management**
   - Why extra MSB
   - Pointer states
   - Increment logic

5. **Full and Empty Detection**
   - Empty condition (simple)
   - Full condition (complex)
   - MSB inversion rationale

6. **Synchronizer Design**
   - Two-stage architecture
   - MTBF analysis
   - Timing diagrams

7. **Complete Architecture**
   - Block diagrams
   - Data flow
   - Integration

8. **Verilog Implementation**
   - Code listings
   - Detailed comments
   - Best practices

9. **Timing Analysis**
   - Latency calculations
   - Performance metrics

10. **Verification Strategy**
    - Test cases
    - Coverage goals

11. **Synthesis Considerations**
    - False paths
    - Constraints

### FIFO_EQUATIONS.tex Contents

**Quick reference format:**
- Gray code conversion formulas
- Pointer management equations
- Full/empty detection logic
- Synchronizer design
- Memory addressing
- Complete operation cycles
- Common mistakes
- Verification checklist

## Key Equations

### Gray Code
```latex
Gray = (Binary >> 1) ⊕ Binary
B[i] = B[i+1] ⊕ G[i]
```

### Empty Condition
```latex
empty = (rptr_gray = wptr_sync)
```

### Full Condition
```latex
full = (wptr = {¬rptr_sync[n:n-1], rptr_sync[n-2:0]})
```

## Figures and Diagrams

The LaTeX documents include:

- **TikZ circuit diagrams**
  - Synchronizer architecture
  - FIFO block diagram
  - Data flow diagrams

- **Timing diagrams**
  - Metastability illustration
  - Clock domain crossing
  - Signal transitions

- **Tables**
  - Binary vs Gray code comparison
  - Pointer states
  - Latency breakdown
  - Test coverage goals

## Customization

### Changing FIFO Parameters

To adapt examples for different FIFO sizes:

1. Find parameter definitions:
```latex
% Example: 16-word FIFO
\newcommand{\fifodepth}{16}
\newcommand{\addrbits}{4}
\newcommand{\ptrbits}{5}
```

2. Update throughout document

### Adding Your Own Diagrams

Example TikZ block:
```latex
\begin{tikzpicture}
    % Your custom diagram
\end{tikzpicture}
```

## Tips for Best Output

1. **Compile twice** - For table of contents and references
2. **Use latexmk** - Automatic dependency handling
3. **Check warnings** - Fix any LaTeX warnings
4. **View PDF** - Ensure diagrams render correctly

## Troubleshooting

### Missing Packages

If you get package errors:
```bash
# Install missing packages
tlmgr install <package-name>

# Or install full distribution
sudo apt-get install texlive-full
```

### Compilation Errors

Common fixes:
```bash
# Clean auxiliary files
latexmk -C

# Rebuild from scratch
latexmk -pdf -f FIFO_TUTORIAL.tex
```

### Diagram Issues

If TikZ diagrams don't render:
```bash
# Ensure TikZ and circuitikz are installed
tlmgr install tikz circuitikz
```

## Online Compilation

If you don't want to install LaTeX locally:

1. **Overleaf** (https://www.overleaf.com)
   - Upload .tex files
   - Compile online
   - Download PDF

2. **Papeeria** (https://papeeria.com)
   - Free LaTeX editor
   - Cloud compilation

## Exporting to Other Formats

### LaTeX → Word
```bash
pandoc FIFO_TUTORIAL.tex -o FIFO_TUTORIAL.docx
```

### LaTeX → HTML
```bash
htlatex FIFO_TUTORIAL.tex
```

### LaTeX → Markdown (already provided!)
See `FIFO_TUTORIAL_COMPLETE.md`

## Additional Resources

- **LaTeX Tutorial**: https://www.overleaf.com/learn
- **TikZ Manual**: https://tikz.dev
- **Beamer (for slides)**: Consider creating presentation version

## License

These documents are educational materials based on:
- Clifford Cummings' SNUG 2002 paper
- Public domain Gray code theory
- Industry best practices

Feel free to use for learning and teaching purposes!

## Contributing

To improve these documents:
1. Edit .tex files
2. Test compilation
3. Submit improvements
4. Update this README if adding new files

## Quick Start

```bash
# Complete tutorial
cd docs
pdflatex FIFO_TUTORIAL.tex && open FIFO_TUTORIAL.pdf

# Quick reference
pdflatex FIFO_EQUATIONS.tex && open FIFO_EQUATIONS.pdf
```

## Questions?

For questions about:
- **LaTeX syntax**: Check Overleaf documentation
- **FIFO design**: See FIFO_TUTORIAL_COMPLETE.md
- **Implementation**: See ../rtl/*.v files
- **Testing**: See ../tb/*.v files

---

**Happy Learning!** 📚✨
