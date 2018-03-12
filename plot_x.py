import numpy as np
import matplotlib.pyplot as plt

x0 = np.loadtxt('intitial.txt')
y = np.loadtxt('iteration1.txt')


fig = plt.figure(figsize=(8,6))
plt.plot(x0,'b',y,'r--')
plt.ylabel('y')
plt.xlabel('Grid point index')

plt.show()
