import React from 'react';

class ErrorBoundary extends React.Component {
  state = { hasError: false, error: null, errorInfo: null };

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    // Отправляем ошибку в iframe или родительское окно
    console.error('Ошибка в React:', error, errorInfo);
    window.parent.postMessage({
      type: 'reactError',
      message: error.message,
      stack: error.stack,
      componentStack: errorInfo.componentStack
    }, '*');
  }

  render() {
    if (this.state.hasError) {
      return <h1>Что-то пошло не так.</h1>;
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
