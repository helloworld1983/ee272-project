#ifndef VERILATOR_DRIVER_H
#define VERILATOR_DRIVER_H

#include <cstddef>
#include <array>
#include <utility>

#include "verilated.h"
#include "verilated_vcd_c.h"

namespace detail {
template <class T, std::size_t N, std::size_t... I>
constexpr std::array<std::remove_cv_t<T>, N>
    to_array_impl(T (&a)[N], std::index_sequence<I...>)
{
    return { {a[I]...} };
}

/// Construct an std::array from a built in array
/// We only need this since std::array doesn't have a convient constructor
template <class T, std::size_t N>
constexpr std::array<std::remove_cv_t<T>, N> to_array(T (&a)[N]) {
    return detail::to_array_impl(a, std::make_index_sequence<N>{});
}
} // detail

template <typename T>
class VerilatorDUT {
    /// Verilator class containing the actual state of the device
    T top_;

    /// Current simulation time.
    ///
    /// This is a 64-bit integer to reduce wrap-over issues.
    uint64_t time_ = 0;

  public:
    /// Write a value to the specified field
    template <typename U, typename V>
    void poke(U T::*m, V v) { top_.*(m) = v; }

    /// Read a value from the specified field
    template <typename V>
    V peek(V T::*m) { return top_.*(m); }

    /// Specialization for array values
    template <typename V, std::size_t N>
    std::array<V, N> peekArray(V (T::*m)[N]) {
      return detail::to_array<V, N>(top_.*(m));
    }

    /// Run the testbench for `n` clock cycles
    /// Note: 10 timesteps == 1 clock cycle
    void step(uint64_t n) {
      for (const auto end = time_ + n; time_ < end; time_++) {
        if ((time_ % 10) == 1) { top_.clock = 1; }
        if ((time_ % 10) == 6) { top_.clock = 0; }
        top_.eval();
      }
    }

    /// Run any cleanup required by the simulator
    void finish() { top_.final(); }
};

#endif
