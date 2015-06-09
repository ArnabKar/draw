require 'mobdebug'.start()

require 'nn'
require 'nngraph'
require 'optim'
require 'image'
local model_utils=require 'model_utils'
local mnist = require 'mnist'


N = 12
A = 28 
B = 28

x = nn.Identity()()
y = nn.Reshape(1,1)(x)
l = {}
for i = 1, A do 
  l[#l + 1] = nn.Copy()(y)  
end
z = nn.JoinTable(2)(l)
l = {}
for i = 1, B do 
  l[#l + 1] = nn.Copy()(z)  
end
z = nn.JoinTable(3)(l) 
duplicate = nn.gModule({x}, {z})



h_dec_n = 100
x = nn.Identity()()
h_dec = nn.Identity()()
gx = nn.Reshape(A, B)(nn.Linear(h_dec_n, A * B)(h_dec))
gx = nn.Reshape(A, B)(nn.Linear(h_dec_n, A * B)(h_dec))
gy = nn.Reshape(A, B)(nn.Linear(h_dec_n, A * B)(h_dec))
delta = nn.Reshape(A, B)(nn.Linear(h_dec_n, A * B)(h_dec))
gamma = nn.Reshape(A, B)(nn.Linear(h_dec_n, A * B)(h_dec))
sigma = nn.Reshape(A, B)(nn.Linear(h_dec_n, A * B)(h_dec))
delta = nn.Exp()(delta)
gamma = nn.Exp()(gamma)
sigma = nn.Exp()(sigma)
gx = nn.AddConstant(1)(gx)
gy = nn.AddConstant(1)(gy)
gx = nn.MulConstant((A + 1) / 2)(gx)
gy = nn.MulConstant((B + 1) / 2)(gy)
delta = nn.MulConstant((math.max(A,B)-1)/(N-1))(delta)

vozrast_x = nn.Identity()()
vozrast_y = nn.Identity()()

filtered = {}

for i = 1, N do
  for j = 1, N do
    mu_i = nn.CAddTable()({gx, nn.MulConstant(i - N/2 - 1/2)(delta)})
    mu_j = nn.CAddTable()({gx, nn.MulConstant(j - N/2 - 1/2)(delta)})
    mu_i = nn.MulConstant(-1)(mu_i)
    mu_j = nn.MulConstant(-1)(mu_j)
    sigma = nn.MulConstant(-1/2)(sigma)
    d_i = nn.CAddTable()({mu_i, vozrast_x})
    d_j = nn.CAddTable()({mu_j, vozrast_y})
    d_i = nn.Power(2)(d_i)
    d_j = nn.Power(2)(d_j)
    exp_i = nn.CMulTable()({d_i, sigma})
    exp_j = nn.CMulTable()({d_j, sigma})
    exp_i = nn.Exp()(exp_i)
    exp_j = nn.Exp()(exp_j)
    filtered[#filtered + 1] = nn.CMulTable()({exp_i, exp_j, x})
  end
end
    
filtered_x = nn.JoinTable()(filtered)
filtered_x = nn.Reshape(N, N)(filtered_x)

m = nn.gModule({x, h_dec, vozrast_x, vozrast_y}, {filtered_x})


