
#Region Public

// Returns the structure of parameters for calling the of operation, the structure can be extended with custom parameters
//
// Returns:
//  Structure:
//   * PrepareData - Boolean - prepare data at server before accessing the driver
//   * ProcessData__ - Boolean - perform data processing at server after accessing the driver
//   * Command - String - string Presentation of the command
//
Function OperationParametersList() Export
	
	Parameters = New Structure();
	Parameters.Insert("PrepareData", False); 
	Parameters.Insert("ProcessData__", False); 
	Parameters.Insert("Command", ""); 
	Return Parameters;
	
EndFunction

// Fills in the Transfer parameter structure to the hardware driver, the structure can be expanded with custom parameters
//
// Returns:
//  Structure:
//   * Result - Boolean - the result of the driver Operation
//   * ErrorText - String - Text Presentation of the error
//
Function OperationData() Export
	
	OperationData = New Structure();
	OperationData.Insert("Result", True);
	OperationData.Insert("ErrorText");
	Return OperationData;
	
EndFunction

#EndRegion

#Region Internal

Function EventLogEvent() Export
	Return NStr("vi = 'Thiết bị chưa được chứng thực';
				|ru = 'Несертифицированное оборудование';
				|en = 'Uncertified peripherals'; fa = 'تجهیزات جانبی گواهی‌نشده';
				|it = 'Несертифицированное оборудование';
				|pl = 'Uncertified peripherals';
				|tr = 'Sertifikalandırılmamış ekipman'");
EndFunction

#EndRegion