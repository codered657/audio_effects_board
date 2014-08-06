#   Audio Effects GUI
#
#   Description: A Tkinter GUI for the Audio Effects Board.
#
#   Notes: None.
#   
#   Revision History:
#       Steven Okai     07/26/14    1) Initial revision.
#       Steven Okai     08/05/14    1) Added UI commands.
# 

from Tkinter import *
import ttk as tk
import serial
import time
import pyfpga.fpgacmd as cmd

class App:

    def __init__(self, master):

        master.title("Audio Effects");

        self.f_chorus = tk.LabelFrame(master, text = "Chorus");
        self.f_chorus.grid(row = 0, column = 0, sticky = N+E+S+W, padx = 5, pady = 5);

        self.f_distortion = tk.LabelFrame(master, text = "Distortion");
        self.f_distortion.grid(row = 0, column = 1, sticky = N+E+S+W, padx = 5, pady = 5);

        self.f_compressor = tk.LabelFrame(master, text = "Compressor");
        self.f_compressor.grid(row = 0, column = 2, sticky = N+E+S+W, padx = 5, pady = 5);

        self.f_chorus_buttons = tk.Frame(self.f_chorus);
        self.f_chorus_buttons.grid(row = 1, column = 0, sticky = W, padx = 5, pady = 5);

        self.f_chorus_sliders = tk.Frame(self.f_chorus);
        self.f_chorus_sliders.grid(row = 0, column = 0, sticky = W, padx = 5, pady = 5);

        self.f_compressor_sliders = tk.Frame(self.f_compressor);
        self.f_compressor_sliders.grid(row = 0, column = 0, sticky = W, padx = 5, pady = 5);

        self.f_compressor_buttons = tk.Frame(self.f_compressor);
        self.f_compressor_buttons.grid(row = 1, column = 0, sticky = W, padx = 5, pady = 5);

        #-------------------------------------------------------------------------------------------
        # Chorus controls
        #-------------------------------------------------------------------------------------------
        self.f_chorus_effect_level = tk.Scale(self.f_chorus_sliders, from_ = 15, to = 0, orient = "vertical", command = self.set_chorus_effect_level);
        self.f_chorus_effect_level.grid(row = 0, column = 0, sticky = W, padx = 5, pady = 5);

        self.f_chorus_width = tk.Scale(self.f_chorus_sliders, from_ = 255, to = 0, orient = "vertical", command = self.set_chorus_width);
        self.f_chorus_width.grid(row = 0, column = 1, sticky = W, padx = 5, pady = 5);

        self.f_chorus_rate = tk.Scale(self.f_chorus_sliders, from_ = 3, to = 0, orient = "vertical", command = self.set_chorus_rate);
        self.f_chorus_rate.grid(row = 0, column = 2, sticky = W, padx = 5, pady = 5);

        self.f_chorus_delay = tk.Scale(self.f_chorus_sliders, from_ = 2047, to = 0, orient = "vertical", command = self.set_chorus_delay);
        self.f_chorus_delay.grid(row = 0, column = 3, sticky = W, padx = 5, pady = 5);

        self.chorus_on = tk.Button(self.f_chorus_buttons, text = "On");
        self.chorus_on.grid(row = 0, column = 0, sticky = W, padx = 5, pady = 5);
  
        self.num_voices = StringVar();
        self.num_voices_values = [" ", "1", "2", "4"];
        self.num_voices.set(self.num_voices_values[1])
        self.chorus_num_voices = tk.OptionMenu(self.f_chorus_buttons, self.num_voices, *self.num_voices_values, command = self.set_chorus_num_voices);
        self.chorus_num_voices.grid(row = 0, column = 1, sticky = E+W, padx = 5, pady = 5);

        #-------------------------------------------------------------------------------------------
        # Compressor controls
        #-------------------------------------------------------------------------------------------
        self.compressor_attack_time = tk.Scale(self.f_compressor_sliders, from_ = 7, to = 0, orient = "vertical", command = self.set_compressor_attack_time);
        self.compressor_attack_time.grid(row = 0, column = 0, sticky = W, padx = 5, pady = 5);

        self.compressor_release_time = tk.Scale(self.f_compressor_sliders, from_ = 7, to = 0, orient = "vertical", command = self.set_compressor_release_time);
        self.compressor_release_time.grid(row = 0, column = 1, sticky = W, padx = 5, pady = 5);

        self.compressor_threshold = tk.Scale(self.f_compressor_sliders, from_ = 31, to = 0, orient = "vertical", command = self.set_compressor_threshold);
        self.compressor_threshold.grid(row = 0, column = 2, sticky = W, padx = 5, pady = 5);

        self.compressor_ratio = tk.Scale(self.f_compressor_sliders, from_ = 63, to = 0, orient = "vertical", command = self.set_compressor_ratio);
        self.compressor_ratio.grid(row = 0, column = 3, sticky = W, padx = 5, pady = 5);

        self.compressor_make_up_gain = tk.Scale(self.f_compressor_sliders, from_ = 15, to = 0, orient = "vertical", command = self.set_compressor_make_up_gain);
        self.compressor_make_up_gain.grid(row = 0, column = 4, sticky = W, padx = 5, pady = 5);

        self.compressor_on = tk.Button(self.f_compressor_buttons, text = "On");
        self.compressor_on.grid(row = 0, column = 0, sticky = W, padx = 5, pady = 5);

        # Progress bars to read current signal amplitude.

        #self.port = serial.Serial(5, 19200, parity = serial.PARITY_ODD, writeTimeout = 1.0, timeout = 5.0);
        #print self.port.name;
        #self.port.write("hi");
        #print self.port.inWaiting();
        #print self.port.read();

    def set_chorus_effect_level(self, level):
        # TODO: Write level...
        print level;
        raise IOError("Help");
        try:
            raise IOError("Failed to update chorus effect level.");
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_chorus_width(self, width):
        # TODO: Write level...
        print width;
        try:
            raise IOError("Failed to update chorus width.");
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_chorus_rate(self, rate):
        # TODO: Write level...
        print rate;
        try:
            raise IOError("Failed to update chorus rate.");
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_chorus_delay(self, delay):
        # TODO: Write level...
        print delay;
        try:
            raise IOError("Failed to update chorus delay.");
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_chorus_num_voices(self, num_voices):
        # TODO: Write level...
        print num_voices;
        try:
            raise IOError("Failed to update chorus number of voices.");
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_compressor_attack_time(self, time):
        # TODO: Write level...
        print time;
        try:
            raise IOError("Failed to update compressor attack time.");
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_compressor_release_time(self, time):
        # TODO: Write level...
        print time;
        try:
            raise IOError("Failed to update compressor release time.");
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_compressor_threshold(self, threshold):
        # TODO: Write level...
        print threshold;
        try:
            raise IOError("Failed to update compressor threshold.");
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_compressor_ratio(self, ratio):
        # TODO: Write level...
        print ratio;
        try:
            raise IOError("Failed to update compressor ratio.");
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_compressor_make_up_gain(self, gain):
        # TODO: Write level...
        print gain;
        try:
            raise IOError("Failed to update compressor make up gain.");
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

if __name__ == "__main__":
    root = Tk();

    app = App(root);

    root.mainloop();
    #root.destroy();