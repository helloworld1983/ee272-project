#ifndef VERILATOR_DRIVER_H
#define VERILATOR_DRIVER_H

#include <cstddef>
#include <array>
#include <algorithm>
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
    /// Current simulation time.
    ///
    /// This is a 64-bit integer to reduce wrap-over issues.
    uint64_t time_ = 0;

  public:
    /// Verilator class containing the actual state of the device
    T top;

    /// Getter for the current cycle
    auto currentCycle() const noexcept { return time_; }

    /// Write a value to the specified field
    template <typename U, typename V>
    void poke(U T::*m, V v) { top.*(m) = v; }

    /// Specialization for array values
    template <typename V, std::size_t N>
    void pokeArray(V (T::*m)[N], const std::array<V, N> &v) {
      std::copy_n(std::begin(v), N, top.*m);
    }

    /// Read a value from the specified field
    template <typename V>
    V peek(V T::*m) {
      top.eval();
      return top.*(m);
    }

    /// Specialization for array values
    template <typename V, std::size_t N>
    std::array<V, N> peekArray(V (T::*m)[N]) {
      top.eval();
      return detail::to_array<V, N>(top.*m);
    }

    /// Run the testbench for `n` clock cycles
    void step(uint64_t n = 1) {
      // Make sure any combinational events have triggered
      top.eval();
      for (const auto end = time_ + n; time_ < end; time_++) {
        // Toggle clock
        top.clock = 1;
        top.eval();
        top.clock = 0;
        top.eval();
      }
    }

    /// Run the testbench until the value is equal
    template <typename V>
    void stepUntil(V T::*m, V v) {
      while (!(peek(m) == v)) { step(); }
    }

    /// Run the testbench until the value is true
    template <typename V>
    void stepUntilTrue(V T::*m) {
      while (!peek(m)) { step(); }
    }

    /// Reset the device
    void reset() {
      top.reset_n = 0;
      top.clock   = 0;
      step(2);
      top.reset_n = 1;
      step();
    }

    /// Run any cleanup required by the simulator
    void finish() { top.final(); }
};

#endif
