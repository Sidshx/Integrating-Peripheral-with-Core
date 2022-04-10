# Integrating_IP-Cores_With_Processor

## A Wishbone controlled PWM(Audio) Controller

Tried out the Verilog code to design Wishbone compatible PWM controller. Wishbone compatibility is one of the way which helps the core to communicate with the parts of the integrated circuit, connects differing cores to one another in a chip.
The main aim was to understand the integration of an IP Core with a processor, and how the core shares the input/output signals and interrupts with the processor.
In this case the integration was studied by reusing an open source code (https://github.com/ZipCPU/wbpwmaudio/blob/master/rtl/wbpwmaudio.v)

### Inputs and Outputs
![image](https://user-images.githubusercontent.com/73933646/161335681-1c6fd644-730d-489f-80c8-1146be261f8c.png)
* i indicates inputs
* o indicates outputs
* wb stands for wishbone signals

![image](https://user-images.githubusercontent.com/73933646/161337638-dc4ce8e1-f17a-4d6c-a286-648b3b018b63.png)
![image](https://user-images.githubusercontent.com/73933646/161339671-119708e8-807f-4aad-8e7a-00da3ed7247e.png)

