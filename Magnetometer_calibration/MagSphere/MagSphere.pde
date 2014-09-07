/*	
	3DScatter v1.1 - June 2012
	Produce, in Processing, a 3D scatter graph from serial data
	Copyright (c) 2011 Hon Bo Xuan <honboxuan at gmail dot com>
	All rights reserved.

	This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
/*
	Notes:
	If you use an Arduino, use the following code snippet to output the 
	vector coordinates in the right format:
	
		Serial.print(0xDE, BYTE);
		Serial.print(vector[0]); //X
		Serial.print(" ");
		Serial.print(vector[1]); //Y
		Serial.print(" ");
		Serial.print(vector[2]); //Z
		Serial.println(" ");
		
	Baud is 115200 and the port is the first in Serial.list(). Just 
	change the parts in line 57 if necessary.
	
	Feel free to drop me an email if you have a suggestion or need help 
	with this.
*/

import processing.opengl.*;
import processing.serial.*;
import java.awt.event.*;

Serial source;
PFont font;

int count = 0;
int[] vals;
PVector[] vecs = new PVector[10000];

int x_max = 0, x_min = 0, y_max = 0, y_min = 0, z_max = 0, z_min = 0;
/*int x_mean = 0, y_mean = 0, z_mean = 0;*/

int x_total = 0, y_total = 0, z_total = 0;
int x_mean = 0, y_mean = 0, z_mean = 0;

int x_length = 0, y_length = 0, z_length = 0;
float length_mean = 0, x_gain = 1, y_gain = 1, z_gain = 1;

float zoom = 0.5;

void setup() {
  size(1000, 1000, OPENGL);
  source = new Serial(this, Serial.list()[0], 115200);
  source.bufferUntil(10);
  frame.addMouseWheelListener(new MouseWheelInput());
  
  font = createFont("ArialMT", 48, true);
  
  vals = new int[3];
}

void draw() {
  background(0);  
  translate(width/2, height/2);
  
  String gain = "Gain: " + x_gain + ", " + y_gain + ", " + z_gain;
  textFont(font, 20);
  fill(255, 255, 255);
  text(gain, -width/2 + 20, height/2 - 20); //Print before flipping Y (mag Z axis) and rotation
  
  //float z = radians(frameCount/2);
  float z = radians(0.5 * mouseX);
  rotateY(z);
  //float r = -0.1; //Minus because before flipping Y
  float r = -0.001 * (mouseY - 500); //Minus because before flipping Y
  rotateX(r * cos(z));
  rotateZ(r * sin(z));

  String centre = x_mean + ", " + y_mean + ", " + z_mean;
  textFont(font, 20);
  fill(255, 255, 255);
  text(centre, 0.5 * x_mean + 20, -0.5 * z_mean, 0.5 * y_mean); //Print before flipping Y (mag Z axis)

  scale(zoom, -zoom, zoom); //Flip Y (mag Z axis)

  noFill();
  stroke(100);
  strokeWeight(1);
  box(1200);

  stroke(0, 255, 255);
  strokeWeight(8);
  point(x_mean, z_mean, y_mean); //Centroid

  stroke(255, 0, 0);
  strokeWeight(2);
  line (300, 0, 0, 275, 0, 25); //Arrow head
  line (300, 0, 0, 275, 0, -25); 
  line (320, -20, 0, 340, 20, 0); //Axis label
  line (320, 20, 0, 340, -20, 0);
  line(-300, 0, 0, 300, 0, 0); //Mag X Red
  
  stroke(0, 0, 255);
  strokeWeight(2);
  line (0, 0, 300, 25, 0, 275); //Arrow head
  line (0, 0, 300, -25, 0, 275); 
  line (0, 20, 320, 0, 0, 330); //Axis label
  line (0, 0, 330, 0, 20, 340);
  line (0, 0, 330, 0, -20, 330);
  line(0, 0, -300, 0, 0, 300); //Mag Y Blue
  
  stroke(0, 255, 0);
  strokeWeight(2);
  line (0, 300, 0, 25, 275, 0); //Arrow head
  line (0, 300, 0, -25, 275, 0);
  line (-10, 350, 0, 10, 350, 0); //Axis label
  line (10, 350, 0, -10, 320, 0); 
  line (-10, 320, 0, 10, 320, 0); 
  line(0, -300, 0, 0, 300, 0); //Mag Z Green

  for (int i = 0; i < count; i++) {
    PVector v = vecs[i];
    stroke(255);
    strokeWeight(3);
    point(v.x, v.y, v.z);
  }
}

void serialEvent(Serial p) {
  if (p.available() > 0) {
    switch (p.read()) {
    case 222:
      
     String linein = p.readStringUntil(10);
     // print(linein);
      if (linein != null) {
        vals = int (split(linein, ' '));
        vecs[count] = new PVector(vals[0], vals[2], vals[1]);
       // print(vals[0]+"\n");
        count++;
        findCentroid();
        findGain();
      }
      break;
    default:
      break;
    }
  }
}

void findCentroid() { //Fixed to find centroid, all points equally weighted
  x_total += vals[0]; //With 10,000 sample limit, should not overflow
  x_mean = x_total / count; 
  y_total += vals[1];
  y_mean = z_total / count; 
  z_total += vals[2];
  z_mean = z_total / count;
}

void findGain() { //Still simplistic
  //Find lengths between max and min of x, y and z
  //Find mean and gain of each axis
  x_length = x_max - x_min;
  y_length = y_max - y_min;
  z_length = z_max - z_min;
  length_mean = (x_length + y_length + z_length) / 3;
  x_gain = x_length / length_mean;
  y_gain = y_length / length_mean;
  z_gain = z_length / length_mean;
}

class MouseWheelInput implements MouseWheelListener{
	void mouseWheelMoved(MouseWheelEvent e) {
		zoom -= 0.05 * e.getWheelRotation();
		zoom = constrain(zoom, 0.2, 2);
	}
} 








