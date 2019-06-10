//grid-based lookup for particles, damatically (!) speeds up the algorithm
class Grid {
  Field[] fields;
  int n_width;
  int n_height;
  float h;
  
  Grid(float wd, float ht, float h) {
    this.h = h;
    n_width = ceil(wd/h);
    n_height = ceil(ht/h);
    fields = new Field[n_width * n_height];
    for (int i=0; i<fields.length; i++) {
      fields[i] = new Field();
    }
  }
  
  Field get_Field(float x, float y) {
    int i_width = floor(x/h);
    int i_height = floor(y/h);
    if ((i_width >= 0) && (i_width < n_width) && (i_height >= 0) && (i_height < n_height)) {
      int index = i_width*n_height + i_height;
      return fields[index];
    }
    else {
      return null;
    }
  }
  
  void add_particle(Particle p) {
    for ( int i=-1; i<2; i++ ) {
      for ( int j= -1; j<2; j++) {
        float x = p.pos.x + h*float(i);
        float y = p.pos.y + h*float(j);
        Field f = get_Field(x, y);
        if (f != null) {
          f.particles.add(p);
        }
      }
    }
  }
  
  void clear_grid() {
    for (Field f:fields) {
      f.particles.clear();
    }
  }
}

class Field {
  ArrayList<Particle> particles;
  
  Field() {
    particles = new ArrayList<Particle>();
  }
}
