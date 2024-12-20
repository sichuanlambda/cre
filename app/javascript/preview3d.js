console.log('preview3d.js loaded');

import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls';

class BuildingPreview {
  constructor(containerId) {
    console.log('BuildingPreview constructor called with containerId:', containerId);
    this.container = document.getElementById(containerId);
    console.log('Container found:', this.container);
    this.init();
  }

  init() {
    console.log('Initializing Three.js scene');
    // Setup scene
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0xf3f4f6);

    // Setup camera
    this.camera = new THREE.PerspectiveCamera(
      75,
      this.container.clientWidth / this.container.clientHeight,
      0.1,
      1000
    );
    this.camera.position.set(200, 200, 200);
    this.camera.lookAt(0, 0, 0);

    // Setup renderer
    this.renderer = new THREE.WebGLRenderer({ antialias: true });
    this.renderer.setSize(this.container.clientWidth, this.container.clientHeight);
    this.container.appendChild(this.renderer.domElement);
    console.log('Renderer added to container');

    // Add controls
    this.controls = new OrbitControls(this.camera, this.renderer.domElement);
    this.controls.enableDamping = true;

    // Add grid
    const gridHelper = new THREE.GridHelper(200, 20);
    this.scene.add(gridHelper);

    // Add lights
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
    this.scene.add(ambientLight);
    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(50, 50, 50);
    this.scene.add(directionalLight);

    this.animate();
    console.log('Scene initialization complete');
  }

  updateBuilding(specs) {
    // Remove existing building if any
    const existingBuilding = this.scene.getObjectByName('building');
    const existingLot = this.scene.getObjectByName('lot');
    if (existingBuilding) this.scene.remove(existingBuilding);
    if (existingLot) this.scene.remove(existingLot);

    // Calculate buildable area
    const buildableWidth = specs.lotWidth - (specs.sideSetback * 2);
    const buildableDepth = specs.lotDepth - specs.frontSetback - specs.rearSetback;
    const height = specs.maxHeight;

    // Create building envelope using ExtrudeGeometry
    const shape = new THREE.Shape();
    const halfWidth = buildableWidth / 2;
    const halfDepth = buildableDepth / 2;

    // Define the building footprint shape
    shape.moveTo(-halfWidth, -halfDepth);
    shape.lineTo(halfWidth, -halfDepth);
    shape.lineTo(halfWidth, halfDepth);
    shape.lineTo(-halfWidth, halfDepth);
    shape.lineTo(-halfWidth, -halfDepth);

    const extrudeSettings = {
      steps: 1,
      depth: height,
      bevelEnabled: false
    };

    const geometry = new THREE.ExtrudeGeometry(shape, extrudeSettings);
    const material = new THREE.MeshPhongMaterial({
      color: 0x2563eb,
      transparent: true,
      opacity: 0.7,
      side: THREE.DoubleSide
    });

    const building = new THREE.Mesh(geometry, material);
    building.name = 'building';
    
    // Rotate and position the building correctly
    building.rotation.x = -Math.PI / 2;
    building.position.set(
      0,
      0,
      (specs.frontSetback - specs.rearSetback) / 2
    );
    this.scene.add(building);

    // Add lot outline
    const lotGeometry = new THREE.BoxGeometry(specs.lotWidth, 0.1, specs.lotDepth);
    const lotMaterial = new THREE.MeshBasicMaterial({
      color: 0x64748b,
      wireframe: true
    });
    const lot = new THREE.Mesh(lotGeometry, lotMaterial);
    lot.name = 'lot';
    this.scene.add(lot);

    // Add setback lines
    this.addSetbackLines(specs);
  }

  addSetbackLines(specs) {
    const material = new THREE.LineBasicMaterial({ color: 0xff0000 });
    
    // Front setback line
    const frontLine = new THREE.BufferGeometry().setFromPoints([
      new THREE.Vector3(-specs.lotWidth/2, 0, -specs.lotDepth/2 + specs.frontSetback),
      new THREE.Vector3(specs.lotWidth/2, 0, -specs.lotDepth/2 + specs.frontSetback)
    ]);
    
    // Rear setback line
    const rearLine = new THREE.BufferGeometry().setFromPoints([
      new THREE.Vector3(-specs.lotWidth/2, 0, specs.lotDepth/2 - specs.rearSetback),
      new THREE.Vector3(specs.lotWidth/2, 0, specs.lotDepth/2 - specs.rearSetback)
    ]);
    
    // Side setback lines
    const leftLine = new THREE.BufferGeometry().setFromPoints([
      new THREE.Vector3(-specs.lotWidth/2 + specs.sideSetback, 0, -specs.lotDepth/2),
      new THREE.Vector3(-specs.lotWidth/2 + specs.sideSetback, 0, specs.lotDepth/2)
    ]);
    
    const rightLine = new THREE.BufferGeometry().setFromPoints([
      new THREE.Vector3(specs.lotWidth/2 - specs.sideSetback, 0, -specs.lotDepth/2),
      new THREE.Vector3(specs.lotWidth/2 - specs.sideSetback, 0, specs.lotDepth/2)
    ]);

    [frontLine, rearLine, leftLine, rightLine].forEach(line => {
      this.scene.add(new THREE.Line(line, material));
    });
  }

  animate() {
    requestAnimationFrame(() => this.animate());
    this.controls.update();
    this.renderer.render(this.scene, this.camera);
  }

  handleResize() {
    const width = this.container.clientWidth;
    const height = this.container.clientHeight;
    this.camera.aspect = width / height;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(width, height);
  }
}

function generateKMLPreview(coords, specs) {
  const [lat, lng] = coords.split(',').map(c => c.trim());
  
  // Calculate building footprint coordinates based on setbacks
  const buildingWidth = specs.lotWidth - (specs.sideSetback * 2);
  const buildingDepth = specs.lotDepth - specs.frontSetback - specs.rearSetback;

  return `<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Building Envelope</name>
    <Placemark>
      <name>Building Envelope</name>
      <Style>
        <PolyStyle>
          <color>7f0000ff</color>
        </PolyStyle>
      </Style>
      <extrude>1</extrude>
      <altitudeMode>relativeToGround</altitudeMode>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              ${lng},${lat},${specs.maxHeight}
              ${lng + 0.0001},${lat},${specs.maxHeight}
              ${lng + 0.0001},${lat + 0.0001},${specs.maxHeight}
              ${lng},${lat + 0.0001},${specs.maxHeight}
              ${lng},${lat},${specs.maxHeight}
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
  </Document>
</kml>`;
}

// Initialize preview when document is loaded
document.addEventListener('DOMContentLoaded', () => {
  console.log('DOMContentLoaded event fired');
  const preview = new BuildingPreview('preview3D');
  window.buildingPreview = preview;
  console.log('BuildingPreview instance created');

  // Add form input listeners
  const form = document.querySelector('form');
  const inputs = form.querySelectorAll('input');
  
  inputs.forEach(input => {
    input.addEventListener('input', () => {
      const coords = form.querySelector('[name="coordinates"]').value;
      const specs = {
        lotWidth: parseFloat(form.querySelector('[name="lot_width"]').value) || 100,
        lotDepth: parseFloat(form.querySelector('[name="lot_depth"]').value) || 150,
        frontSetback: parseFloat(form.querySelector('[name="front_setback"]').value) || 25,
        rearSetback: parseFloat(form.querySelector('[name="rear_setback"]').value) || 20,
        sideSetback: parseFloat(form.querySelector('[name="side_setback"]').value) || 10,
        maxHeight: parseFloat(form.querySelector('[name="max_height"]').value) || 35,
      };
      
      // Update 3D preview
      preview.updateBuilding(specs);
      
      // Update KML preview
      const kmlPreview = document.getElementById('kmlPreview');
      if (coords && kmlPreview) {
        kmlPreview.textContent = generateKMLPreview(coords, specs);
      }
    });
  });

  // Initial render
  const initialCoords = form.querySelector('[name="coordinates"]').value;
  const initialSpecs = {
    lotWidth: 100,
    lotDepth: 150,
    frontSetback: 25,
    rearSetback: 20,
    sideSetback: 10,
    maxHeight: 35,
  };

  preview.updateBuilding(initialSpecs);

  // Initial KML preview
  const kmlPreview = document.getElementById('kmlPreview');
  if (initialCoords && kmlPreview) {
    kmlPreview.textContent = generateKMLPreview(initialCoords, initialSpecs);
  }

  // Handle window resize
  window.addEventListener('resize', () => preview.handleResize());
});

export default BuildingPreview; 