package launcher

import (
	"errors"
	"sync"
)

type Launcher struct {
	errs chan error
	wg   *sync.WaitGroup
}

func New() *Launcher {
	return &Launcher{
		errs: make(chan error, 1000),
		wg:   &sync.WaitGroup{},
	}
}

func (l *Launcher) Go(f func() error) {
	l.wg.Add(1)
	go func() {
		defer l.wg.Done()
		l.errs <- f()
	}()
}

func (l *Launcher) Wait() error {
	l.wg.Wait()
	close(l.errs)
	var err error
	for err2 := range l.errs {
		err = errors.Join(err, err2)
	}
	return err
}
