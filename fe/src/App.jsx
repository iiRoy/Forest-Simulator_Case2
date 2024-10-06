import { Button, ButtonGroup, CheckboxField, SliderField, SwitchField } from '@aws-amplify/ui-react';
import { useRef, useState } from 'react'

import '@aws-amplify/ui-react/styles.css';

import Plotly from 'plotly.js/dist/plotly';

Plotly.newPlot('mydiv', [{
  y: [1,2,3,1,3],
  mode: 'lines',
  line: {color: '#80CAF6'}
}]);

function App() {
  let [location, setLocation] = useState("");
  let [gridSize, setGridSize] = useState(40);
  let [probability_of_spread, setProbability] = useState(100);
  let [simSpeed,setSimSpeed] = useState(2);
  let [trees, setTrees] = useState([]);
  let [iterations, setIterations] = useState(0);
  let [burntPerc, setBurntPerc] = useState(0);
  let [density, setDensity] = useState(80);
  let [sliderGridSize, setSliderGridSize] = useState(40);
  let [south_wind_speed, setSouthWindSpeed] = useState(0);
  let [west_wind_speed, setWestWindSpeed] = useState(0);
  let [bigJumps, setBigJumps] = useState(false);

  const burntTrees = useRef(null);
  const running = useRef(null);

  let setup = () => {
    setGridSize(sliderGridSize);
    fetch("http://localhost:8000/simulations", {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        dim: [sliderGridSize, sliderGridSize],
        probability_of_spread: probability_of_spread,
        density: density / 100,
        south_wind_speed: south_wind_speed,
        west_wind_speed: west_wind_speed,
        bigJumps: bigJumps
      })
    }).then(resp => resp.json())
    .then(data => {
      setLocation(data["Location"]);
      setTrees(data["trees"]);
      setIterations(0);
      setBurntPerc(0);
    });
  }

  let handleStart = () => {
    burntTrees.current = [];
    running.current = setInterval(() => {
      fetch("http://localhost:8000" + location)
      .then(res => res.json())
      .then(data => {
        let burnt = data["trees"].filter(t => t.status == "burnt").length / data["trees"].length;
        burntTrees.current.push(burnt);
        setTrees(data["trees"]);
        setIterations(prev => prev + 1);
        setBurntPerc((burnt * 100).toFixed(2));
      });
      }, 3000 / simSpeed);
  };

  let handleStop = () => {
    clearInterval(running.current);
  
    Plotly.newPlot('mydiv', [{
      y: burntTrees.current,
      mode: 'lines',
      line: {color: '#80CAF6'}
    }]);
  };

  let burning = trees.filter(t => t.status == "burning").length;
  if (burning == 0) handleStop();
  let offset = (500 - gridSize * 12) / 2;

  return (
    <>
      <ButtonGroup variation="primary">
        <Button onClick={setup}>Setup</Button>
        <Button onClick={handleStart}>Start</Button>
        <Button onClick={handleStop}>Stop</Button>
      </ButtonGroup>

      <SliderField label="Grid size" min={10} max={40} step={10}
        value={sliderGridSize} onChange={setSliderGridSize} />
      <SliderField label="Simulation speed" min={1} max={30}
        value={simSpeed} onChange={setSimSpeed} />
      <SliderField label="Spread Probability" min={0} max={100} step={1}
        value={probability_of_spread} onChange={setProbability} />
      <SliderField label="Density" min={0} max={100} step={10}
        value={density} onChange={setDensity} />
      <SliderField label="South-North Wind" min={-50} max={50} step={1}
        value={south_wind_speed} onChange={setSouthWindSpeed} />
      <SliderField label="West-East Wind" min={-50} max={50} step={1}
        value={west_wind_speed} onChange={setWestWindSpeed} />
      <SwitchField label="Big Jump"
        checked={bigJumps} onChange={(e) => setBigJumps(e.target.checked)} />
      <p>Iterations: {iterations}</p> 
      <p>Burnt trees percentage: {burntPerc}%</p>

      <svg width="500" height="500" xmlns="http://www.w3.org/2000/svg" style={{backgroundColor:"white"}}>
      {
        trees.map(tree =>
          <image
            key={tree["id"]}
            x={offset + 12*(tree["pos"][0] - 1)}
            y={offset + 12*(tree["pos"][1] - 1)}
            width={15} href={
              tree["status"] === "green" ? "./greentree.svg" :
              (tree["status"] === "burning" ? "./burningtree.svg" :
                "./burnttree.svg")
            }
          />
        )
      }
      </svg>

    </>
  )
}

export default App