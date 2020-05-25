/*
 * application.h
 *
 *  Created on: Mar 18, 2018
 *      Author: user
 */

#ifndef APPLICATION_H_
#define APPLICATION_H_

#include "main.h"
#include "stm32l4xx_hal.h"
#include "jsmn.h"
//#include "eeprom.h"

// packet variables
#define MSG_BUFFER_SIZE 256
#define HEADER_SIZE 5
#define FOOTER_SIZE 2
#define UART_RX_BUFFER_SIZE 1
#define UART_TX_BUFFER_SIZE 1
// variables
extern UART_HandleTypeDef huart1;
extern UART_HandleTypeDef huart2;
extern ADC_HandleTypeDef hadc1;
extern DAC_HandleTypeDef hdac1;
extern SPI_HandleTypeDef hspi3;

////////////////////
// UART Variables //
////////////////////
extern __IO ITStatus UartReady;
extern uint8_t aRxBuffer[UART_RX_BUFFER_SIZE];
extern uint8_t aTxBuffer[UART_TX_BUFFER_SIZE];
extern char messageSend[MSG_BUFFER_SIZE];
extern char messageRec[MSG_BUFFER_SIZE];

// json buffer
extern char json[MSG_BUFFER_SIZE];
extern uint16_t jsonLength;

// incoming packet
typedef struct PacketMSG_struct_ {
	// Receive message variables
	uint8_t header[HEADER_SIZE];
	uint8_t footer[FOOTER_SIZE];
	uint8_t syncIndex; // sync index for header / footer
	uint8_t syncFlag; // 0 - waiting for header, 1 -  waiting for footer, 2 - verify footer, 3 - finish footer send to parser, flash buffer
	// buffer
	uint16_t bufferIndex; // buffer index
	uint8_t buffer[MSG_BUFFER_SIZE];
} PacketMSG_struct;
extern PacketMSG_struct packetMSG;

// Registers
extern __IO uint32_t Dac1_Reg;

#define ADC_BUFFER_SIZE (1024*25) // maximum preallocated buffer size

#ifdef WIRELESS
#define PACKET_SIZE (256*2) // Packet size to send out bytes
#else
#define PACKET_SIZE (ADC_BUFFER_SIZE*2) // Packet size to send out bytes
#endif

#define SIG_THRESH 2500// Range: 4095/2 <-> 4095 (mid range 4095/2)
#define THRESH_KEEP_ON 10000 // timeout on threshold detection
extern uint16_t adcLatency;
extern uint16_t sigThresh;

extern uint8_t recordState;
extern uint16_t threshOn;
extern uint16_t threshOnSet;
extern uint16_t buffADC[ADC_BUFFER_SIZE];
extern uint16_t buffADC_index;
extern uint16_t buffOut_index;

// PGA settings
extern uint8_t pgaGain;
extern uint8_t pgaChannel;

/* Virtual address defined by the user: 0xFFFF value is prohibited */
#define EE_threshOnSet_add 	0x1111
#define EE_adcLatency_add 	0x2222
#define EE_sigThresh_add 	0x3333
#define EE_pgaGain_add 		0x4444
#define EE_pgaChannel_add 	0x5555

/* Virtual address array*/
//extern uint16_t VirtAddVarTab[NB_OF_VAR];

// application functions
void setup_init(void);
//void EE_setup_init (void);
#ifdef WIRELESS
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart1);
#else
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart2);
#endif

int jsoneq(const char *json, jsmntok_t *tok, const char *s);
void parsePacket(void);
void initPacket(void);
void serialEvent(uint8_t inByte);
void writePGA(uint8_t gain , uint8_t channel );
void ackSend(uint8_t state, uint8_t micNum);
void sendBuffOut (void);


#endif /* APPLICATION_H_ */
