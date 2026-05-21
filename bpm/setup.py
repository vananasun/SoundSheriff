# setup.py
from setuptools import setup
from Cython.Build import cythonize
import numpy

setup(
    name="bpm",
    ext_modules=cythonize("bpm.pyx", compiler_directives={'language_level': "3"}),
    include_dirs=[numpy.get_include()],
    zip_safe=False,
)