package future

import "errors"

var ErrFutureCanceled = errors.New("future canceled")

type Future[T any] struct {
	value    T
	canceled bool
	c        chan struct{}
}

func New[T any]() *Future[T] {
	return &Future[T]{
		c: make(chan struct{}),
	}
}

func (m *Future[T]) Set(value T) {
	m.value = value
	close(m.c)
}

func (m *Future[T]) Cancel() {
	m.canceled = true
	close(m.c)
}

func (m *Future[T]) Get() (T, error) {
	<-m.c
	if m.canceled {
		return *new(T), ErrFutureCanceled
	}
	return m.value, nil
}
