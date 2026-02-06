import { ThemeProvider } from './context/ThemeContext';
import { Home } from './views/Home';

function App() {
  return (
    <ThemeProvider>
      <Home />
    </ThemeProvider>
  );
}

export default App;
