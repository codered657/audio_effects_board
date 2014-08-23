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

ADDR_TOP_LEVEL = 0x00;

ADDR_CHORUS = dict(ENABLE       = 0x00,
                   EFFECT_LEVEL = 0x04,
                   NUM_VOICES   = 0x08,
                   WIDTH        = 0x0C,
                   RATE         = 0x10,
                   DELAY        = 0x14
                  );

ADDR_SOFT_CLIPPER = dict(ENABLE         = 0x00,
                         THRESHOLD      = 0x04,
                         COEFFICIENT    = 0x08
                        );

ADDR_DISTORTION = 0x00;

ADDR_COMPRESSOR = dict(ENABLE       = 0x00,
                       ATTACK_TIME  = 0x04,
                       RELEASE_TIME = 0x08,
                       THRESHOLD    = 0x0C,
                       RATIO        = 0x10,
                       MAKE_UP_GAIN = 0x14
                      );

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

    def set_chorus_enable(self, enable):
        # TODO: Write level...
        print level;
        try:
            cmd.write_verify(ADDR_CHORUS["ENABLE"], level, self.port);
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_chorus_effect_level(self, level):
        # TODO: Write level...
        print level;
        try:
            cmd.write_verify(ADDR_CHORUS["EFFECT_LEVEL"], level, self.port);
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_chorus_width(self, width):
        # TODO: Write level...
        print width;
        try:
            cmd.write_verify(ADDR_CHORUS["WIDTH"], level, self.port);
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_chorus_rate(self, rate):
        # TODO: Write level...
        print rate;
        try:
            cmd.write_verify(ADDR_CHORUS["RATE"], level, self.port);
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_chorus_delay(self, delay):
        # TODO: Write level...
        print delay;
        try:
            cmd.write_verify(ADDR_CHORUS["DELAY"], level, self.port);
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_chorus_num_voices(self, num_voices):
        # TODO: Write level...
        print num_voices;
        try:
            cmd.write_verify(ADDR_CHORUS["NUM_VOICES"], level, self.port);
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_compressor_enable(self, enable):
        # TODO: Write level...
        print level;
        try:
            cmd.write_verify(ADDR_COMPRESSOR["ENABLE"], level, self.port);
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_compressor_attack_time(self, time):
        # TODO: Write level...
        print time;
        try:
            cmd.write_verify(ADDR_COMPRESSOR["ATTACK_TIME"], level, self.port);
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_compressor_release_time(self, time):
        # TODO: Write level...
        print time;
        try:
            cmd.write_verify(ADDR_COMPRESSOR["RELEASE_TIME"], level, self.port);
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_compressor_threshold(self, threshold):
        # TODO: Write level...
        print threshold;
        try:
            cmd.write_verify(ADDR_COMPRESSOR["THRESHOLD"], level, self.port);
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_compressor_ratio(self, ratio):
        # TODO: Write level...
        print ratio;
        try:
            cmd.write_verify(ADDR_COMPRESSOR["RATIO"], level, self.port);
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

    def set_compressor_make_up_gain(self, gain):
        # TODO: Write level...
        print gain;
        try:
            cmd.write_verify(ADDR_COMPRESSOR["MAKE_UP_GAIN"], level, self.port);
        except IOError, err:
            sys.stderr.write('ERROR: %s\n' % str(err));

if __name__ == "__main__":
    root = Tk();

    app = App(root);

    root.mainloop();
    #root.destroy();