<table class="regdef" id="Reg_control">
 <tr>
  <th class="regdef" colspan=5>
   <div>conv1d_control.CONTROL @ 0x0</div>
   <div><p>Accelerator main control configuration</p></div>
   <div>Reset default = 0x0, mask 0x3ffff</div>
  </th>
 </tr>
<tr><td colspan=5><table class="regpic"><tr><td class="bitnum">31</td><td class="bitnum">30</td><td class="bitnum">29</td><td class="bitnum">28</td><td class="bitnum">27</td><td class="bitnum">26</td><td class="bitnum">25</td><td class="bitnum">24</td><td class="bitnum">23</td><td class="bitnum">22</td><td class="bitnum">21</td><td class="bitnum">20</td><td class="bitnum">19</td><td class="bitnum">18</td><td class="bitnum">17</td><td class="bitnum">16</td></tr><tr><td class="unused" colspan=14>&nbsp;</td>
<td class="fname" colspan=2>KERNEL_LEN...</td>
</tr>
<tr><td class="bitnum">15</td><td class="bitnum">14</td><td class="bitnum">13</td><td class="bitnum">12</td><td class="bitnum">11</td><td class="bitnum">10</td><td class="bitnum">9</td><td class="bitnum">8</td><td class="bitnum">7</td><td class="bitnum">6</td><td class="bitnum">5</td><td class="bitnum">4</td><td class="bitnum">3</td><td class="bitnum">2</td><td class="bitnum">1</td><td class="bitnum">0</td></tr><tr><td class="fname" colspan=2 style="font-size:46.15384615384615%">...KERNEL_LEN</td>
<td class="fname" colspan=6>INPUT_CH</td>
<td class="fname" colspan=7>TILE_SIZE</td>
<td class="fname" colspan=1 style="font-size:60.0%">START</td>
</tr></table></td></tr>
<tr><th width=5%>Bits</th><th width=5%>Type</th><th width=5%>Reset</th><th>Name</th><th>Description</th></tr><tr><td class="regbits">0</td><td class="regperm">rw</td><td class="regrv">0x0</td><td class="regfn">START</td><td class="regde"><p>Start bit. Set to 1 to start convolution.</p></td><tr><td class="regbits">7:1</td><td class="regperm">rw</td><td class="regrv">0x0</td><td class="regfn">TILE_SIZE</td><td class="regde"><p>Output tile size (Number of time steps to process)</p></td><tr><td class="regbits">13:8</td><td class="regperm">rw</td><td class="regrv">0x0</td><td class="regfn">INPUT_CH</td><td class="regde"><p>Number of input channels</p></td><tr><td class="regbits">17:14</td><td class="regperm">rw</td><td class="regrv">0x0</td><td class="regfn">KERNEL_LEN</td><td class="regde"><p>Length of the kernel (K)</p></td></table>
<br>
<table class="regdef" id="Reg_pointers">
 <tr>
  <th class="regdef" colspan=5>
   <div>conv1d_control.POINTERS @ 0x4</div>
   <div><p>Memory Buffer Start Addresses (Word Indices 0-127)</p></div>
   <div>Reset default = 0x0, mask 0x7f7f7f</div>
  </th>
 </tr>
<tr><td colspan=5><table class="regpic"><tr><td class="bitnum">31</td><td class="bitnum">30</td><td class="bitnum">29</td><td class="bitnum">28</td><td class="bitnum">27</td><td class="bitnum">26</td><td class="bitnum">25</td><td class="bitnum">24</td><td class="bitnum">23</td><td class="bitnum">22</td><td class="bitnum">21</td><td class="bitnum">20</td><td class="bitnum">19</td><td class="bitnum">18</td><td class="bitnum">17</td><td class="bitnum">16</td></tr><tr><td class="unused" colspan=9>&nbsp;</td>
<td class="fname" colspan=7>OUTPUT_PTR</td>
</tr>
<tr><td class="bitnum">15</td><td class="bitnum">14</td><td class="bitnum">13</td><td class="bitnum">12</td><td class="bitnum">11</td><td class="bitnum">10</td><td class="bitnum">9</td><td class="bitnum">8</td><td class="bitnum">7</td><td class="bitnum">6</td><td class="bitnum">5</td><td class="bitnum">4</td><td class="bitnum">3</td><td class="bitnum">2</td><td class="bitnum">1</td><td class="bitnum">0</td></tr><tr><td class="unused" colspan=1>&nbsp;</td>
<td class="fname" colspan=7>WEIGHT_PTR</td>
<td class="unused" colspan=1>&nbsp;</td>
<td class="fname" colspan=7>INPUT_PTR</td>
</tr></table></td></tr>
<tr><th width=5%>Bits</th><th width=5%>Type</th><th width=5%>Reset</th><th>Name</th><th>Description</th></tr><tr><td class="regbits">6:0</td><td class="regperm">rw</td><td class="regrv">0x0</td><td class="regfn">INPUT_PTR</td><td class="regde"><p>Start address of Input buffer (Word Index 0-127)</p></td><tr><td class="regbits">7</td><td></td><td></td><td></td><td>Reserved</td></tr><tr><td class="regbits">14:8</td><td class="regperm">rw</td><td class="regrv">0x0</td><td class="regfn">WEIGHT_PTR</td><td class="regde"><p>Start address of Weight buffer (Word Index 0-127)</p></td><tr><td class="regbits">15</td><td></td><td></td><td></td><td>Reserved</td></tr><tr><td class="regbits">22:16</td><td class="regperm">rw</td><td class="regrv">0x0</td><td class="regfn">OUTPUT_PTR</td><td class="regde"><p>Start address of Output buffer (Word Index 0-127)</p></td></table>
<br>
<table class="regdef" id="Reg_status">
 <tr>
  <th class="regdef" colspan=5>
   <div>conv1d_control.STATUS @ 0x8</div>
   <div><p>Accelerator status register</p></div>
   <div>Reset default = 0x0, mask 0x3</div>
  </th>
 </tr>
<tr><td colspan=5><table class="regpic"><tr><td class="bitnum">31</td><td class="bitnum">30</td><td class="bitnum">29</td><td class="bitnum">28</td><td class="bitnum">27</td><td class="bitnum">26</td><td class="bitnum">25</td><td class="bitnum">24</td><td class="bitnum">23</td><td class="bitnum">22</td><td class="bitnum">21</td><td class="bitnum">20</td><td class="bitnum">19</td><td class="bitnum">18</td><td class="bitnum">17</td><td class="bitnum">16</td></tr><tr><td class="unused" colspan=16>&nbsp;</td>
</tr>
<tr><td class="bitnum">15</td><td class="bitnum">14</td><td class="bitnum">13</td><td class="bitnum">12</td><td class="bitnum">11</td><td class="bitnum">10</td><td class="bitnum">9</td><td class="bitnum">8</td><td class="bitnum">7</td><td class="bitnum">6</td><td class="bitnum">5</td><td class="bitnum">4</td><td class="bitnum">3</td><td class="bitnum">2</td><td class="bitnum">1</td><td class="bitnum">0</td></tr><tr><td class="unused" colspan=14>&nbsp;</td>
<td class="fname" colspan=1 style="font-size:75.0%">DONE</td>
<td class="fname" colspan=1 style="font-size:42.857142857142854%">RUNNING</td>
</tr></table></td></tr>
<tr><th width=5%>Bits</th><th width=5%>Type</th><th width=5%>Reset</th><th>Name</th><th>Description</th></tr><tr><td class="regbits">0</td><td class="regperm">rw</td><td class="regrv">0x0</td><td class="regfn">RUNNING</td><td class="regde"><p>This bit is set to 1 when the accelerator is running.</p></td><tr><td class="regbits">1</td><td class="regperm">rw</td><td class="regrv">0x0</td><td class="regfn">DONE</td><td class="regde"><p>This bit is set to 1 when the accelerator has finished.</p></td></table>
<br>
