/*
 * application.c
 *
 *  Created on: Mar 18, 2018
 *      Author: user
 */

/* Commands:
 * json:{"gain":0,"channel":0} // approximately 10ms to parse and send a response
 * json:{"threshOn":1000}
 * json:{"sigThresh":0.5} // range [0 - 1]
 * json:{"adcLatency":1000} // range [0 - (ADC_BUFFER_SIZE - 1)]
 * json:{"recordState":0} // debug state for sending recorded audio to PC [0,1]
 */
#include "application.h"
#include "main.h"
#include "stm32f3xx_hal.h"
#include <stdio.h>  /* sprintf */
#include <string.h> /* strlen */
#include <stdlib.h> /* atoi  */
#include "jsmn.h"
#include "eeprom.h"

// variables:
uint16_t buffADC[ADC_BUFFER_SIZE] = { 0 };
uint16_t buffADC_index = 0;
uint16_t buffOut_index = 0;
uint16_t threshOnSet = THRESH_KEEP_ON;
uint16_t threshOn = 0;

// record play back state;
uint8_t recordState = 0;

// signal latency (maximum ADC_BUFFER_SIZE)
uint16_t adcLatency = 1000;

// signal trigger threshold
uint16_t sigThresh = SIG_THRESH;

// PGA settings
uint8_t pgaGain = 0;
uint8_t pgaChannel = 0;

/* Virtual address array*/
uint16_t VirtAddVarTab[NB_OF_VAR] = {EE_threshOnSet_add, EE_adcLatency_add, EE_sigThresh_add, EE_pgaGain_add, EE_pgaChannel_add};



// UART status
__IO ITStatus UartReady = RESET;
// UART buffers
char messageSend[MSG_BUFFER_SIZE];
char messageRec[MSG_BUFFER_SIZE];

// UART interrupt buffers
uint8_t aRxBuffer[UART_RX_BUFFER_SIZE];
uint8_t aTxBuffer[UART_TX_BUFFER_SIZE] = " ";

// json buffer
char json[MSG_BUFFER_SIZE];
uint16_t jsonLength = 0;

// incoming packet
PacketMSG_struct packetMSG;

// functions
void setup_init(void) {
	// init PGA_CS pin to high (disable)
	HAL_GPIO_WritePin(PGA_CS_GPIO_Port, PGA_CS_Pin , GPIO_PIN_SET);
	HAL_Delay(100); // delay for PGA PowerUp
	// Init PGA SPI
	HAL_GPIO_WritePin(PGA_CS_GPIO_Port, PGA_CS_Pin , GPIO_PIN_RESET);
	uint16_t spiTransmit[1] = {0x0000};
	HAL_SPI_Transmit(&hspi1, (uint8_t*)spiTransmit, 1, 5000);
	HAL_GPIO_WritePin(PGA_CS_GPIO_Port, PGA_CS_Pin , GPIO_PIN_SET);

	// init adc / dac
	HAL_ADC_Start(&hadc1);
	HAL_DAC_Start(&hdac1, DAC_CHANNEL_1);
	HAL_DAC_Start(&hdac2, DAC_CHANNEL_1);

	// init dac register
	Dac1_Reg = (uint32_t) (hdac1.Instance);
	Dac1_Reg += DAC_DHR12R1_ALIGNMENT(DAC_ALIGN_12B_R);
	Dac2_Reg = (uint32_t) (hdac2.Instance);
	Dac2_Reg += DAC_DHR12R1_ALIGNMENT(DAC_ALIGN_12B_R);

	// initialize UART in interrupt mode
#ifdef WIRELESS
	if (HAL_UART_Receive_IT(&huart1, (uint8_t *) aRxBuffer, sizeof(aRxBuffer))
			!= HAL_OK) {
		Error_Handler();
	}
#else
	if (HAL_UART_Receive_IT(&huart2, (uint8_t *) aRxBuffer, sizeof(aRxBuffer))
			!= HAL_OK) {
		Error_Handler();
	}
#endif
	// set flag for waiting for incoming data
	UartReady = RESET;
}

// initialize variables from eeprom
void EE_setup_init (void){
	// temp variables
	uint16_t EE_temp_data = 0;

	// update variables from eeprom
	/* Unlock the Flash Program Erase controller */
	HAL_FLASH_Unlock();

	/* EEPROM Init */
	EE_Init();

	// read variables from EEPROM
	EE_temp_data = threshOnSet;
	EE_ReadVariable(EE_threshOnSet_add,  &EE_temp_data);
	threshOnSet = EE_temp_data;

	// read variables from EEPROM
	EE_temp_data = adcLatency;
	EE_ReadVariable(EE_adcLatency_add,  &EE_temp_data);
	adcLatency = EE_temp_data;

	// read variables from EEPROM
	EE_temp_data = sigThresh;
	EE_ReadVariable(EE_sigThresh_add,  &EE_temp_data);
	sigThresh = EE_temp_data;

	// read variables from EEPROM
	EE_temp_data = (uint16_t) pgaGain;
	EE_ReadVariable(EE_pgaGain_add,  &EE_temp_data);
	pgaGain = (uint8_t) EE_temp_data;

	// read variables from EEPROM
	EE_temp_data = (uint16_t) pgaChannel;
	EE_ReadVariable(EE_pgaChannel_add,  &EE_temp_data);
	pgaChannel = (uint8_t) EE_temp_data;

	// update PGA Settings
	writePGA(pgaGain , pgaChannel);

	/* Lock the Flash Program Erase controller */
	//HAL_FLASH_Lock();
}

/**
 * @brief  Rx Transfer completed callback
 * @param  UartHandle: UART handle
 * @note   This example shows a simple way to report end of DMA Rx transfer, and
 *         you can add your own implementation.
 * @retval None
 */


#ifdef WIRELESS
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart1) {
	/* Set transmission flag: transfer complete */
	UartReady = SET;
}
#else
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart2) {
	/* Set transmission flag: transfer complete */
	UartReady = SET;
}
#endif

// Serial Event function
void serialEvent(uint8_t inByte) {
	// detect start message , end message
	switch (packetMSG.syncFlag) {
	// waiting for header
	case 0: {
		if (packetMSG.header[packetMSG.syncIndex] == inByte) {
			packetMSG.syncIndex++;
			if (packetMSG.syncIndex == HEADER_SIZE) { // finish header SYNC
				packetMSG.syncFlag = 1; // start collecting data, wait for footer
				packetMSG.bufferIndex = 0;
				packetMSG.syncIndex = 0;
			}
		} else { // re-init sync
			packetMSG.syncIndex = 0;
		}
		//pc.printf("case 0 , %d  \r\n",packetMSG.syncIndex);
		break;
	}
	// waiting for footer
	case 1: {
		// add byte to buffer
		packetMSG.buffer[packetMSG.bufferIndex] = inByte;
		packetMSG.bufferIndex++;
		if (packetMSG.bufferIndex >= MSG_BUFFER_SIZE) { // buffer overflow
			// reset buffer
			packetMSG.bufferIndex = 0;
			packetMSG.syncIndex = 0;
			packetMSG.syncFlag = 0;
		} else if (packetMSG.footer[packetMSG.syncIndex] == inByte) { // footer char recieved
			packetMSG.syncIndex++;
			packetMSG.syncFlag = 2; // move to verify footer
		}
		//pc.printf("case 2 , %d  \r\n",packetMSG.syncIndex);
		break;
	}
	// verify footer
	case 2: {
		// add byte to buffer
		packetMSG.buffer[packetMSG.bufferIndex] = inByte;
		packetMSG.bufferIndex++;
		if (packetMSG.bufferIndex >= MSG_BUFFER_SIZE) { // buffer overflow
			// reset buffer
			packetMSG.bufferIndex = 0;
			packetMSG.syncIndex = 0;
			packetMSG.syncFlag = 0;
		} else if (packetMSG.footer[packetMSG.syncIndex] == inByte) { // footer char received
			packetMSG.syncIndex++;
			if (packetMSG.syncIndex == FOOTER_SIZE) { // finish footer SYNC
				packetMSG.syncFlag = 3;
				// copy packet to json buffer
				memcpy(&json, &packetMSG.buffer, packetMSG.bufferIndex);
				json[packetMSG.bufferIndex] = 0; //NULL; // end with NULL to indicate end of string
				jsonLength = packetMSG.bufferIndex;
				// send msg to parse.
				parsePacket();
				// reset buffer
				packetMSG.bufferIndex = 0;
				packetMSG.syncIndex = 0;
				packetMSG.syncFlag = 0;
			}
		} else { // footer broke restart wait for footer
			packetMSG.syncFlag = 1;
			// verify that it didn't broke on first footer char
			if (packetMSG.footer[0] == inByte) {
				packetMSG.syncIndex = 1;
			} else {
				packetMSG.syncIndex = 0;
			}
		}
		break;
	}
	default: {
		// something went wrong
		break;
	}
	} // end switch
} // end serialEvent

// compare to json tokens
int jsoneq(const char *json, jsmntok_t *tok, const char *s) {
	if (tok->type == JSMN_STRING && (int) strlen(s) == tok->end - tok->start
			&& strncmp(json + tok->start, s, tok->end - tok->start) == 0) {
		return 0;
	}
	return -1;
}

// Packet Parser
void parsePacket(void) {

	// send received message
	//HAL_UART_Transmit(&huart2, (uint8_t*) json, jsonLength, 5000); // send json packet
	// parse with JSMN parser
	int i;
	int r;
	jsmn_parser p;
	jsmntok_t t[20]; /* We expect no more than 128 tokens */

	jsmn_init(&p);
	r = jsmn_parse(&p, json, strlen(json), t, sizeof(t) / sizeof(t[0]));

	// test received  message
	//sprintf(messageSend, "r: %.d\r\n", r);
	//HAL_UART_Transmit(&huart2, (uint8_t*) messageSend, strlen(messageSend),5000);  // send json packet
	// verify root token is the specific mic
	if (jsoneq(json, &t[1], "mic") == 0) {
		// copy token into array - consider switching to strndup()
		char numString[10];
		sprintf(numString, "%.*s", t[2].end - t[2].start,json + t[2].start);
		int micAddr = atoi(numString);
#ifdef DEBUGGING_MSGS
		sprintf(messageSend, "micAddr: %d\r\n", micAddr);
		HAL_UART_Transmit(&huart2, (uint8_t*) messageSend,strlen(messageSend), 5000);  // send json packet
#endif
		// verify its the correct mic or the golden mic
		if ((micAddr == MICNUM) || (micAddr == 0)) {
			ackSend(1, MICNUM);
			/* Loop over all keys of the root object */
			for (i = 3; i < r; i++) {

				if (jsoneq(json, &t[i], "getSettings") == 0) {
					sprintf(messageSend, "{\"Settings\":%d,\"gain\":%d,\"channel\":%d,\"threshOn\":%d,\"sigThresh\":%d,\"adcLatency\":%d,\"recordState\":%d}\r\n"
							, MICNUM , pgaGain , pgaChannel , threshOnSet , sigThresh , adcLatency , recordState );
#ifdef WIRELESS
					HAL_UART_Transmit(&huart1, (uint8_t*) messageSend,strlen(messageSend), 5000);
					HAL_Delay(100); // allow xbee to finish packet
#else
					HAL_UART_Transmit(&huart2, (uint8_t*) messageSend,strlen(messageSend), 5000);
#endif

				}if (jsoneq(json, &t[i], "gain") == 0) {

					// copy token into array - consider switching to strndup()
					char numString[10];
					sprintf(numString, "%.*s", t[i + 1].end - t[i + 1].start,json + t[i + 1].start);
					pgaGain = atoi(numString);
					EE_WriteVariable(EE_pgaGain_add,  (uint16_t)pgaGain);
#ifdef DEBUGGING_MSGS
					sprintf(messageSend, "pgaGain: %d\r\n", pgaGain);
					HAL_UART_Transmit(&huart2, (uint8_t*) messageSend,strlen(messageSend), 5000);  // send json packet
#endif
					// update PGA Settings
					writePGA(pgaGain , pgaChannel);

					i++;
				}else if (jsoneq(json, &t[i], "channel") == 0) {

					// copy token into array - consider switching to strndup()
					char numString[10];
					sprintf(numString, "%.*s", t[i + 1].end - t[i + 1].start,json + t[i + 1].start);
					pgaChannel = atoi(numString);
					EE_WriteVariable(EE_pgaChannel_add,  (uint16_t)pgaChannel);
#ifdef DEBUGGING_MSGS
					sprintf(messageSend, "pgaChannel: %d\r\n", pgaChannel);
					HAL_UART_Transmit(&huart2, (uint8_t*) messageSend,strlen(messageSend), 5000);  // send json packet
#endif
					// update PGA Settings
					writePGA(pgaGain , pgaChannel);

					i++;
				}else if (jsoneq(json, &t[i], "threshOn") == 0) {

					// copy token into array - consider switching to strndup()
					char numString[10];
					sprintf(numString, "%.*s", t[i + 1].end - t[i + 1].start,json + t[i + 1].start);
					threshOnSet = atoi(numString);
					EE_WriteVariable(EE_threshOnSet_add,  (uint16_t)threshOnSet);
#ifdef DEBUGGING_MSGS
					sprintf(messageSend, "threshOnSet: %d \r\n", (int)threshOnSet);
					HAL_UART_Transmit(&huart2, (uint8_t*) messageSend,strlen(messageSend), 5000);  // send json packet
#endif
					i++;
				}else if (jsoneq(json, &t[i], "sigThresh") == 0) {

					// copy token into array - consider switching to strndup()
					char numString[10];
					sprintf(numString, "%.*s", t[i + 1].end - t[i + 1].start,json + t[i + 1].start);
					float sigThreshFloat = atof(numString);
					if (sigThreshFloat>1) sigThreshFloat=1;
					if (sigThreshFloat<0) sigThreshFloat=0;
					sigThresh = (uint16_t) ( ((sigThreshFloat) * 4095/2) + 4095/2);
					EE_WriteVariable(EE_sigThresh_add,  (uint16_t)sigThresh);
#ifdef DEBUGGING_MSGS
					sprintf(messageSend, "sigThresh: %d \r\n", (int)sigThresh);
					HAL_UART_Transmit(&huart2, (uint8_t*) messageSend,strlen(messageSend), 5000);  // send json packet
#endif
					i++;
				}else if (jsoneq(json, &t[i], "adcLatency") == 0) {

					// copy token into array - consider switching to strndup()
					char numString[10];
					sprintf(numString, "%.*s", t[i + 1].end - t[i + 1].start,json + t[i + 1].start);
					adcLatency = atoi(numString);
					if (adcLatency>=ADC_BUFFER_SIZE) adcLatency = (ADC_BUFFER_SIZE - 1);
					if (adcLatency<0) adcLatency = 0; // no latency
					EE_WriteVariable(EE_adcLatency_add,  (uint16_t)adcLatency);
#ifdef DEBUGGING_MSGS
					sprintf(messageSend, "adcLatency: %d \r\n", (int)adcLatency);
					HAL_UART_Transmit(&huart2, (uint8_t*) messageSend,strlen(messageSend), 5000);  // send json packet
#endif
					i++;
				}else if (jsoneq(json, &t[i], "recordState") == 0) {

					// copy token into array - consider switching to strndup()
					char numString[10];
					sprintf(numString, "%.*s", t[i + 1].end - t[i + 1].start,json + t[i + 1].start);
					recordState = atoi(numString);
#ifdef DEBUGGING_MSGS

					sprintf(messageSend, "recordState: %d \r\n", (int)recordState);
					HAL_UART_Transmit(&huart2, (uint8_t*) messageSend,strlen(messageSend), 5000);  // send json packet
#endif
					i++;
				}
			} /* End loop over all keys of the root object */
		} // end correct Mic address
	} // end Mic token
}

// initialize packet struct
void initPacket(void) {
	// init variables to default:
	packetMSG.header[0] = 'j';
	packetMSG.header[1] = 's';
	packetMSG.header[2] = 'o';
	packetMSG.header[3] = 'n';
	packetMSG.header[4] = ':';

	packetMSG.footer[0] = 13; // /r
	packetMSG.footer[1] = 10; // /n

	packetMSG.syncIndex = 0; // sync index for header / footer
	packetMSG.syncFlag = 0; // 0 - waiting for header, 1 -  waiting for footer, 2 - verify footer, 3 - finish footer send to parser, flash buffer
	packetMSG.bufferIndex = 0; // buffer index
} // end init Packet struct

// update PGA module
void writePGA(uint8_t gain , uint8_t channel ){

	// limit to valid input
	if (gain > 7) gain = 7;
	if (channel > 1) channel = 1;

	// update PGA
	uint8_t writeMSB = 0x2A;
	uint8_t writeLSB = ((gain << 4) | channel);
	HAL_GPIO_WritePin(PGA_CS_GPIO_Port, PGA_CS_Pin , GPIO_PIN_RESET);
	uint16_t spiTransmit[1] = {((writeMSB<<8) | (writeLSB))};
	HAL_SPI_Transmit(&hspi1, (uint8_t*)spiTransmit, 1, 5000);
	HAL_GPIO_WritePin(PGA_CS_GPIO_Port, PGA_CS_Pin , GPIO_PIN_SET);
}

// send ack true false & mic number
void ackSend(uint8_t state, uint8_t micNum){
	sprintf(messageSend, "{\"Ack\":%d,\"Mic\":%d}\r\n",state,micNum);
#ifdef WIRELESS
	HAL_UART_Transmit(&huart1, (uint8_t*) messageSend,strlen(messageSend), 5000);
	HAL_Delay(100); // allow xbee to finish packet
#else
	HAL_UART_Transmit(&huart2, (uint8_t*) messageSend,strlen(messageSend), 5000);
#endif
}

// send adc buffer out (playback via uart)
void sendBuffOut (void){
	// pull down interrupt IO
	D2_INT_GPIO_Port->BRR = D2_INT_Pin;
	// start of transmission
	sprintf(messageSend, "{\"Recording\":\"Start\",\"Binary\":%d,\"bufferIndex\":%d}\r\n",(int)PACKET_SIZE,(int)buffADC_index); //buffADC_index  buffOut_index
#ifdef WIRELESS
	HAL_UART_Transmit(&huart1, (uint8_t*) messageSend,strlen(messageSend), 5000);
	HAL_Delay(100); // allow xbee to finish packet
#else
	HAL_UART_Transmit(&huart2, (uint8_t*) messageSend,strlen(messageSend), 5000);
#endif
	// send out packet
#ifdef WIRELESS
	HAL_UART_Transmit(&huart1, (uint8_t*) buffADC, PACKET_SIZE , 5000);
	HAL_Delay(100); // allow xbee to finish packet
#else
	HAL_UART_Transmit(&huart2, (uint8_t*) buffADC, PACKET_SIZE , 5000);
#endif


	// sent out in packets of 256 samples PACKET_SIZE if more packets available
	for (int ii = PACKET_SIZE ; ii <= ADC_BUFFER_SIZE*2-PACKET_SIZE; ii = ii+PACKET_SIZE){
		sprintf(messageSend, "{\"Recording\":\"Packet\",\"Binary\":%d}\r\n",(int)PACKET_SIZE);
#ifdef WIRELESS
		HAL_UART_Transmit(&huart1, (uint8_t*) messageSend,strlen(messageSend), 5000);
		HAL_Delay(100); // allow xbee to finish packet
#else
		HAL_UART_Transmit(&huart2, (uint8_t*) messageSend,strlen(messageSend), 5000);
#endif

		// binary packet
#ifdef WIRELESS
		HAL_UART_Transmit(&huart1, ((uint8_t*) buffADC) + ii, PACKET_SIZE , 5000);
		HAL_Delay(100); // allow xbee to finish packet
#else
		HAL_UART_Transmit(&huart2, ((uint8_t*) buffADC) + ii, PACKET_SIZE , 5000);
#endif

	} // todo - send remaining packet if packet size not a round divider of buffer

	// end of transmission
	sprintf(messageSend,"{\"Recording\":\"End\"}\r\n");
#ifdef WIRELESS
	HAL_UART_Transmit(&huart1, (uint8_t*) messageSend,strlen(messageSend), 5000);
	HAL_Delay(100); // allow xbee to finish packet
#else
	HAL_UART_Transmit(&huart2, (uint8_t*) messageSend,strlen(messageSend), 5000);
#endif

	// toggle D2 to indicate end of transmission
	D2_INT_GPIO_Port->BSRR = D2_INT_Pin;
	HAL_Delay(1);
	D2_INT_GPIO_Port->BRR = D2_INT_Pin;
}
