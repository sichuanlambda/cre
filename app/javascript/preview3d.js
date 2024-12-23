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
    const existingRoof = this.scene.getObjectByName('roof');
    if (existingBuilding) this.scene.remove(existingBuilding);
    if (existingLot) this.scene.remove(existingLot);
    if (existingRoof) this.scene.remove(existingRoof);

    // Calculate buildable area
    const buildableWidth = specs.lotWidth - (specs.sideSetback * 2);
    const buildableDepth = specs.lotDepth - specs.frontSetback - specs.rearSetback;
    
    // Adjust building height to account for roof
    const buildingHeight = specs.roofStyle && specs.roofStyle !== 'none' 
      ? specs.maxHeight - specs.roofHeight 
      : specs.maxHeight;

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
      depth: buildingHeight,
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

    // Add roof after building
    this.addRoof(
      buildableWidth,
      buildableDepth,
      buildingHeight,
      specs.roofHeight || 10,
      specs.roofStyle || 'none',
      specs.roofOverhang || 2,
      specs
    );
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

  addRoof(buildableWidth, buildableDepth, baseHeight, roofHeight, roofStyle, overhang, specs) {
    const existingRoof = this.scene.getObjectByName('roof');
    if (existingRoof) this.scene.remove(existingRoof);

    if (roofStyle === 'none') return;

    const roofGeometry = this.generateRoofGeometry(buildableWidth, buildableDepth, roofHeight, roofStyle, overhang);
    const roofMaterial = new THREE.MeshPhongMaterial({
      color: 0x8b4513,
      side: THREE.DoubleSide
    });

    const roof = new THREE.Mesh(roofGeometry, roofMaterial);
    roof.rotation.x = -Math.PI / 2;
    roof.position.set(
      0,
      baseHeight,
      (specs.frontSetback - specs.rearSetback) / 2
    );
    roof.name = 'roof';
    this.scene.add(roof);
  }

  generateRoofGeometry(width, depth, height, style, overhang = 2) {
    const totalWidth = width + (overhang * 2);
    const totalDepth = depth + (overhang * 2);
    const halfWidth = totalWidth / 2;
    const halfDepth = totalDepth / 2;

    switch (style) {
      case 'gabled': {
        const shape = new THREE.Shape();
        // Create a triangular profile for the gabled roof
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
        // Create the peak by scaling the top vertices
        const positions = geometry.attributes.position.array;
        for (let i = 0; i < positions.length; i += 3) {
          if (positions[i + 2] === height) { // If this is a top vertex
            positions[i] = positions[i] * (1 - positions[i + 1] / totalDepth); // Scale X based on Y position
          }
        }
        geometry.attributes.position.needsUpdate = true;
        geometry.computeVertexNormals();
        return geometry;
      }
      
      case 'hipped': {
        const geometry = new THREE.BufferGeometry();
        const vertices = new Float32Array([
          // Front face
          -halfWidth, -halfDepth, 0,
          halfWidth, -halfDepth, 0,
          0, 0, height,
          
          // Back face
          -halfWidth, halfDepth, 0,
          halfWidth, halfDepth, 0,
          0, 0, height,
          
          // Left face
          -halfWidth, -halfDepth, 0,
          -halfWidth, halfDepth, 0,
          0, 0, height,
          
          // Right face
          halfWidth, -halfDepth, 0,
          halfWidth, halfDepth, 0,
          0, 0, height
        ]);
        
        geometry.setAttribute('position', new THREE.BufferAttribute(vertices, 3));
        geometry.computeVertexNormals();
        return geometry;
      }

      case 'mansard': {
        const shape = new THREE.Shape();
        const slopeInset = totalWidth * 0.2;
        
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
        // Create the mansard slope by moving the top vertices inward
        const positions = geometry.attributes.position.array;
        for (let i = 0; i < positions.length; i += 3) {
          if (positions[i + 2] === height) { // If this is a top vertex
            positions[i] *= (1 - slopeInset / halfWidth);
            positions[i + 1] *= (1 - slopeInset / halfDepth);
          }
        }
        geometry.attributes.position.needsUpdate = true;
        geometry.computeVertexNormals();
        return geometry;
      }

      case 'flat':
        return new THREE.BoxGeometry(totalWidth, totalDepth, height * 0.1);

      default:
        return null;
    }
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
  const [lat, lng] = coords.split(',').map(c => parseFloat(c.trim()));
  
  // Convert feet to degrees (approximate)
  const latDegreePerFoot = 1.0 / 364000.0;
  const lngDegreePerFoot = 1.0 / (364000.0 * Math.cos(lat * Math.PI / 180));
  
  // Calculate buildable area
  const buildableWidth = specs.lotWidth - (specs.sideSetback * 2);
  const buildingDepth = specs.lotDepth - specs.frontSetback - specs.rearSetback;

  // Adjust building height to account for roof
  const buildingHeight = specs.roofStyle && specs.roofStyle !== 'none' 
    ? specs.maxHeight - specs.roofHeight 
    : specs.maxHeight;

  // Calculate corners (clockwise from northwest)
  const footprint = [
    // NW corner
    [lat + (buildingDepth/2 * latDegreePerFoot),
     lng - (buildableWidth/2 * lngDegreePerFoot)],
    // NE corner
    [lat + (buildingDepth/2 * latDegreePerFoot),
     lng + (buildableWidth/2 * lngDegreePerFoot)],
    // SE corner
    [lat - (buildingDepth/2 * latDegreePerFoot),
     lng + (buildableWidth/2 * lngDegreePerFoot)],
    // SW corner
    [lat - (buildingDepth/2 * latDegreePerFoot),
     lng - (buildableWidth/2 * lngDegreePerFoot)],
    // Close the polygon by repeating NW corner
    [lat + (buildingDepth/2 * latDegreePerFoot),
     lng - (buildableWidth/2 * lngDegreePerFoot)]
  ];

  // Format coordinates for KML (longitude,latitude,altitude)
  const coordinates = footprint
    .map(point => `${point[1]},${point[0]},${buildingHeight}`)
    .join('\n              ');

  // If there's a roof, add a second polygon for it
  let roofPolygon = '';
  if (specs.roofStyle && specs.roofStyle !== 'none') {
    const roofOverhang = specs.roofOverhang || 2;
    const totalWidth = buildableWidth + (roofOverhang * 2);
    const totalDepth = buildingDepth + (roofOverhang * 2);

    const roofFootprint = [
      // NW corner
      [lat + (totalDepth/2 * latDegreePerFoot),
       lng - (totalWidth/2 * lngDegreePerFoot)],
      // NE corner
      [lat + (totalDepth/2 * latDegreePerFoot),
       lng + (totalWidth/2 * lngDegreePerFoot)],
      // SE corner
      [lat - (totalDepth/2 * latDegreePerFoot),
       lng + (totalWidth/2 * lngDegreePerFoot)],
      // SW corner
      [lat - (totalDepth/2 * latDegreePerFoot),
       lng - (totalWidth/2 * lngDegreePerFoot)],
      // Close the polygon
      [lat + (totalDepth/2 * latDegreePerFoot),
       lng - (totalWidth/2 * lngDegreePerFoot)]
    ];

    const roofCoordinates = roofFootprint
      .map(point => `${point[1]},${point[0]},${specs.maxHeight}`)
      .join('\n              ');

    roofPolygon = `
    <Placemark>
      <name>Roof</name>
      <Style>
        <PolyStyle>
          <color>7f4b2213</color>
        </PolyStyle>
      </Style>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              ${roofCoordinates}
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>`;
  }

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
              ${coordinates}
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>${roofPolygon}
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
        roofHeight: parseFloat(form.querySelector('[name="roof_height"]').value) || 10,
        roofStyle: form.querySelector('[name="roof_style"]').value || 'none',
        roofOverhang: parseFloat(form.querySelector('[name="roof_overhang"]').value) || 2,
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
    roofHeight: 10,
    roofStyle: 'none',
    roofOverhang: 2,
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