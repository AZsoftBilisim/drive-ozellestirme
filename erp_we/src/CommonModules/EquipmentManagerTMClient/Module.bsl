
#Region Public

// Parameters:
// 	Form - ClientApplicationForm
// 	TabularSectionName - String
// 
// Returns:
//  FormDataStructure, FormDataCollectionItem, FormDataTreeItem -
Function CurrentRow(Form, TabularSectionName = "Goods") Export
	
	CurrentRow = Form.Items[TabularSectionName].CurrentData;
	
	If CurrentRow = Undefined Then
		MessageText = NStr("vi = 'Cần chọn dòng mà cần nhận trọng lượng cho dòng đó.';
							|ru = 'Необходимо выбрать строку, для которой необходимо получить вес.';
							|en = 'It is required to select a line to get weight for it.'; fa = 'It is required to select a line to get weight for it.';
							|it = 'È necessario selezionare la riga per la quale si desidera ottenere il peso.';
							|pl = 'Należy wybrać wiersz, dla którego trzeba otrzymać ciężar.';
							|tr = 'Ağırlığı alınacak bir satır seç.'");
		CommonClient.MessageToUser(MessageText);
	EndIf;
	
	Return CurrentRow;
	
EndFunction

// In the procedure, you need to implement an algorithm for converting data from the subsystem of the connected equipment.
//
// Parameters:
//  Parameter - Array - incoming data.
//
// Returns:
//  Array - array of structures with properties:
//   * Barcode - String -
//   * Count - Number -
Function ConvertDataFromScannerToArray(Parameter) Export
	
	EquipmentManagerTMClient.ProcessEvent();
	
	Data = New Array;
	Data.Add(ConvertDataFromScannerToStructure(Parameter));
	
	Return Data;
	
EndFunction

// In the procedure, you need to implement an algorithm for converting data from the subsystem of the connected equipment.
//
// Parameters:
//  Parameter - Array - incoming data.
//
// Returns:
//  Structure - structure with properties:
//   * Barcode - String -
//   * Count - Number -
Function ConvertDataFromScannerToStructure(Parameter) Export
	
	EquipmentManagerTMClient.ProcessEvent();
	
	If Parameter[1] = Undefined Then
		Data = New Structure("Barcode, Count", Parameter[0], 1);    // We get the barcode from the main data
	Else
		Data = New Structure("Barcode, Count", Parameter[1][1], 1); // We get the barcode from the additional data
	EndIf;
	
	Return Data;
	
EndFunction

Function EquipmentAttached(DeviceID) Export
	
	ConnectedDevice = EquipmentManagerClient.GetConnectedDevice(DeviceID);

	If ConnectedDevice = Undefined Then
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

Function ThereIsRawEvent() Export
	
	Return (HLConnectedHardwareEventProcessed = False);
	
EndFunction

Procedure ProcessEvent() Export
	
	HLConnectedHardwareEventProcessed = True;
	
EndProcedure

Procedure ReportError(ExecutionResult) Export
	
	MessageText = NStr("vi = 'Khi thực hiện thao tác đã xảy ra lỗi:""%ErrorDescription%"".';
						|ru = 'При выполнении операции произошла ошибка:""%ErrorDescription%"".';
						|en = 'An error occurred while executing the operation:""%ErrorDescription%"".'; fa = 'An error occurred while executing the operation:""%ErrorDescription%"".';
						|it = 'Si è verificato un errore durante esecuzione dell''operazione:""%ErrorDescription%"".';
						|pl = 'Przy wykonaniu operacji zaistniał błąd:""%ErrorDescription%"".';
						|tr = 'İşlem gerçekleştirilirken hata oluştu: ""%ErrorDescription%"".'");
	MessageText = StrReplace(MessageText, "%ErrorDescription%", ExecutionResult.ErrorDescription);
	CommonClient.MessageToUser(MessageText);
	
EndProcedure

#EndRegion