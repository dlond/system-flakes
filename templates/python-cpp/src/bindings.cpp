#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <pybind11/numpy.h>
#include "myproject/core.h"
#include "myproject/math_ops.h"

namespace py = pybind11;

// Helper to convert numpy array to std::vector
std::vector<double> numpy_to_vector(py::array_t<double> arr) {
    py::buffer_info buf = arr.request();
    double* ptr = static_cast<double*>(buf.ptr);
    return std::vector<double>(ptr, ptr + buf.size);
}

// Helper to convert std::vector to numpy array
py::array_t<double> vector_to_numpy(const std::vector<double>& vec) {
    return py::array_t<double>(vec.size(), vec.data());
}

PYBIND11_MODULE(_myproject_ext, m) {
    m.doc() = "Python bindings for myproject C++ library";
    
    // Version info
    #ifdef VERSION_INFO
        m.attr("__version__") = VERSION_INFO;
    #else
        m.attr("__version__") = "dev";
    #endif
    
    // Core functions
    m.def("greet", &myproject::greet, "Greet a person by name",
          py::arg("name"));
    
    m.def("add_numbers", &myproject::add_numbers, "Add two numbers",
          py::arg("a"), py::arg("b"));
    
    // Vector operations with numpy support
    m.def("add_vectors", [](py::array_t<double> a, py::array_t<double> b) {
        return vector_to_numpy(myproject::add_vectors(
            numpy_to_vector(a), numpy_to_vector(b)));
    }, "Add two numpy arrays element-wise",
       py::arg("a"), py::arg("b"));
    
    m.def("dot_product", [](py::array_t<double> a, py::array_t<double> b) {
        return myproject::dot_product(numpy_to_vector(a), numpy_to_vector(b));
    }, "Compute dot product of two numpy arrays",
       py::arg("a"), py::arg("b"));
    
    m.def("vector_norm", [](py::array_t<double> v) {
        return myproject::vector_norm(numpy_to_vector(v));
    }, "Compute Euclidean norm of a numpy array",
       py::arg("v"));
    
    // Matrix class
    py::class_<myproject::Matrix>(m, "Matrix")
        .def(py::init<size_t, size_t>(), 
             "Create matrix with given dimensions",
             py::arg("rows"), py::arg("cols"))
        .def(py::init<const std::vector<std::vector<double>>&>(),
             "Create matrix from 2D list",
             py::arg("data"))
        .def_property_readonly("rows", &myproject::Matrix::rows)
        .def_property_readonly("cols", &myproject::Matrix::cols)
        .def("at", py::overload_cast<size_t, size_t>(&myproject::Matrix::at),
             "Get element at position (i, j)",
             py::arg("i"), py::arg("j"),
             py::return_value_policy::reference_internal)
        .def("__getitem__", [](const myproject::Matrix& m, py::tuple idx) {
            if (idx.size() != 2) {
                throw py::index_error("Matrix indices must be a tuple of two integers");
            }
            size_t i = idx[0].cast<size_t>();
            size_t j = idx[1].cast<size_t>();
            return m.at(i, j);
        })
        .def("__setitem__", [](myproject::Matrix& m, py::tuple idx, double val) {
            if (idx.size() != 2) {
                throw py::index_error("Matrix indices must be a tuple of two integers");
            }
            size_t i = idx[0].cast<size_t>();
            size_t j = idx[1].cast<size_t>();
            m.at(i, j) = val;
        })
        .def("__add__", &myproject::Matrix::operator+)
        .def("__mul__", &myproject::Matrix::operator*)
        .def("to_numpy", [](const myproject::Matrix& m) {
            auto vec = m.to_vector();
            return py::array_t<double>({m.rows(), m.cols()}, vec.data());
        }, "Convert to numpy array")
        .def("__repr__", [](const myproject::Matrix& m) {
            return "<Matrix " + std::to_string(m.rows()) + "x" + 
                   std::to_string(m.cols()) + ">";
        });
}