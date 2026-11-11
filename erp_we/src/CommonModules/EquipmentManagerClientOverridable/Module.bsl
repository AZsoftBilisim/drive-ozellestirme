
#Region Public

// Returns the current date, converted to the session's time zone.
// It is intended to be used instead of the current Date () function.
//
// Returns:
//  Date
//
Function SessionDate() Export
	
	Return CommonClient.SessionDate();
	
EndFunction

#Region CREEquipment

// Redefines the available CCT for receipt fiscalization
// Parameters:
//  ReceiptDetails_ - Structure - details of the fiscal receipt
//  ListOfDevices - Array - list of available CCTS for fiscalization
//  CREDeviceID - CatalogRef.Peripherals - the selected CCPS for fiscal
//  StandardProcessing - Boolean - performing standard processing
//
Procedure AvailableCCTForFiscalization(ReceiptDetails_, ListOfDevices, CREDeviceID, StandardProcessing = True) Export

EndProcedure

// Overrides the printing of the slip receipt of the acquiring operation. 
// Parameters:
//  PrintingSlipReceipt - Boolean - Determines whether the slip receipt will be printed, True by default.  
//  FullSlipReceipt  - Boolean - Determines which slip check will be printed full or short, by default True. 
//  StandardProcessing - Boolean - performing standard processing.
//
Procedure PrintingSlipReceiptOfAcquiringOperation(PrintingSlipReceipt, FullSlipReceipt, StandardProcessing) Export
	
	
EndProcedure   

// Event when opening a shift at the KKT 
// Parameters:
//  CREDeviceID - CatalogRef.Peripherals - selected CCT
//  RegistrationParameters - Structure - FN registration parameters
//
Procedure WhenOpeningShiftOnKKT(CREDeviceID, RegistrationParameters) Export
	
	
EndProcedure

// Event after successful fiscalization of a receipt for a KKT with marked goods 
// Parameters:
//  CREDeviceID - CatalogRef.Peripherals - selected CCT
//  MTDisposalReport - Structure - Report on the disposal of MT
//
Procedure WhenFiscalizingReceiptWithMarkedGoods(CREDeviceID, MTDisposalReport) Export
	
	
EndProcedure

#EndRegion

// Overrides the output of the QR code of the receipt to the buyer's display after fiscalization. 
// Parameters:
//  OutputOfReceiptQRCode - Boolean - Displaying the QR code of the receipt on the buyer's display 
//  StandardProcessing - Boolean - performing standard processing
//
Procedure DisplayingQRCodeOfReceiptOnBuyerSDisplayAfterFiscalization(OutputOfReceiptQRCode, StandardProcessing) Export
	
EndProcedure

// Overrides the event format from input devices.
// Parameters:
//  NewFormat - Boolean - Events from input devices work in a new format 
//  StandardProcessing - Boolean - performing standard processing
//
Procedure InputDevicesEventNewFormat(NewFormat, StandardProcessing) Export
	
EndProcedure

// Sets the mode whether the installation of the 1C extension is required to work in the browser
// 
// Parameters:
//  Mode - Boolean - if True, then the installation of the extension will be required
//
Procedure SetConnectionModeOfComputerInformationExtension(Mode) Export
	
EndProcedure

// Install the 1C extension to work in the web client.
// 
// Parameters:
//  Notification - Description of the notification that you want to call after installing the extension
//  Text - Recommended text to display when requesting the installation of an extension
//  StandardProcessing - Boolean - if True, then the library itself will ask the 
//                         user a question and install the extension
//
Procedure Install_Extension(Notification, Text, StandardProcessing) Export
	
EndProcedure

#Region WorkingWithHardwareInstanceForm

// Additional actions that can be overridden with a controlled shape in the Instance of equipment
// in the event the "Ajar".
//
// Parameters:
//  Object - CatalogObject.Peripherals - object of the connected equipment.
//  ThisForm - ClientApplicationForm - owner form.
//  Cancel - Boolean - a sign of failure.
//
Procedure HardwareInstanceWhenOpened(Object, ThisForm, Cancel) Export
	
EndProcedure

// Additional overridable actions with the managed form in the hardware Instance
// during the "pre-Close" event.
//
//
// Parameters:
//  Object - CatalogObject.Peripherals - object of the connected equipment.
//  ThisForm - ClientApplicationForm - owner form.
//  Cancel - Boolean - a sign of failure.
//  StandardProcessing - Boolean - indicates standard processing.
//
Procedure EquipmentInstanceBeforeClosing(Object, ThisForm, Cancel, StandardProcessing) Export
	
EndProcedure

// Additional overridable actions with the managed form in the hardware Instance
// during the "pre-Write" event.
//
// Parameters:
//  Object - CatalogObject.Peripherals - object of the connected equipment.
//  ThisForm - ClientApplicationForm - owner form.
//  Cancel - Boolean - a sign of failure.
//  WriteParameters - Structure - settings of recording equipment.
//
Procedure HardwareInstanceBeforeWrite(Object, ThisForm, Cancel, WriteParameters) Export
	
EndProcedure

// Additional overridable actions with the managed form in the hardware Instance
// during the "post-Recording" event.
//
// Parameters:
//  Object - CatalogObject.Peripherals - object of the connected equipment.
//  ThisForm - ClientApplicationForm - owner form.
//  WriteParameters - Structure - settings of recording equipment.
//
Procedure HardwareInstanceAfterRecording(Object, ThisForm, WriteParameters) Export
	
EndProcedure

// Additional redefinable actions with the managed form in the hardware Instance
// when the "navigationlink Processing" event occurs.
//
// Parameters:
//  Object - CatalogObject.Peripherals - object of the connected equipment.
//  ThisForm - ClientApplicationForm - owner form.
//  FormattedStringURL - String - navigation links.
//  StandardProcessing - Boolean - indicates standard processing.
//
Procedure HardwareInstanceHandlingNavigationLink(Object, ThisForm, FormattedStringURL, StandardProcessing) Export
	
EndProcedure

// Additional actions that can be overridden with a controlled shape in the Instance of equipment
// in the event of "Tiobarbituratami".
//
// Parameters:
//  Object - CatalogObject.Peripherals - object of the connected equipment.
//  ThisForm - ClientApplicationForm - owner form.
//  Var_ThisObject - CatalogObject.Peripherals - the current object of the connected hardware.
//  Item - FormField - the element to change.
//  ValueSelected - EnumRef.PeripheralTypes - selected value.
//
Procedure EquipmentInstanceEquipmentTypeSelection(Object, ThisForm, Var_ThisObject, Item, ValueSelected) Export
	
EndProcedure

// Additional overridable actions with the managed form in the Hardware Instance
// of the plug-in procedure "Plug-in_When changing the Form element"
//
// Parameters:
//  Object - CatalogObject.Peripherals - object of the connected equipment.
//  Var_ThisObject - CatalogObject.Peripherals - the current object of the connected equipment..
//  Item - FormField - the element to change.
//
Procedure HardwareInstanceONChangingFormElement(Object, Var_ThisObject, Item) Export
	
EndProcedure

#EndRegion

#Region WorkingWithFiscalOperationsInstanceForm

// Additional redefined actions with the managed form in Fiscal operations
// when the event "processing a navigational Link".
//
// Parameters:
//  Record - InformationRegisterRecordManager.FiscalTransactions
//  ThisForm - ClientApplicationForm
//  FormattedStringURL - String
//  StandardProcessing - Boolean - indicates standard processing.
//
Procedure RecordFormFiscalOperationsNavigationLinkProcessing(Record, ThisForm, FormattedStringURL, StandardProcessing) Export
	
EndProcedure

#EndRegion


#Region DistributedFiscalization

// Overridable actions after opening a receipt in the receipt queue.
//
// Parameters:
//  ExecutionParameters - Structure - Command Execution Parameters
//  AdditionalParameters - Arbitrary
//
Procedure FiscalizationOfChecksInQueueAfterOpeningCheck(ExecutionParameters, AdditionalParameters) Export
	
EndProcedure

// Overridable actions after a receipt printing error in the receipt queue.
//
// Parameters:
//  ExecutionParameters - Structure - Command Execution Parameters
//  AdditionalParameters - Arbitrary
//
Procedure FiscalizationOfReceiptsInQueueAfterReceiptPrintingError(ExecutionParameters, AdditionalParameters) Export
	
EndProcedure

#EndRegion

#Region MessageToTechnicalSupport

// In the procedure, you can allow or prohibit sending BPO messages to technical support
//
// Parameters:
//  Send - Boolean - with standard processing, True
//  StandardProcessing - Boolean - indicates standard processing.
//
Procedure SendMessagesToTechnicalSupport(Send, StandardProcessing) Export
	
EndProcedure

// Preparing the text of a message to the technical support service
//
// Parameters:
//  MessageText - String - the text of the message that will be inserted in the "Message template" field on the site.
//  ErrorText - String - the error text passed to the message sending procedure.
//
Procedure PrepareTextOfMessageInTechnicalSupport(MessageText, ErrorText) Export
	
EndProcedure

#EndRegion

#Region BatchProcessing

// The procedure in which the text content of the slip check can be generated
//
// Parameters:
//   Type - String - Type of slip receipt: 
//         "Regular" - a regular slip-check printed in the body of the fiscal check;
//         "Electronic" - a slip-check printed in the case of an electronic fiscal check;
//         "Refusal" is a slip-check printed in case of failure to perform an acquiring operation,
//                         or performing an emergency cancellation of an acquiring operation.
//   DataForTemplate - Structure - data for creating a slip receipt:
//     * ReceiptFiscalizationParameters - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//     * ParametersOfAcquiringOperation - See PeripheralsPaymentSystemsServerClientServer.ParametersOfAcquiringOperation
//     * ResultOfAcquiringOperationExecution - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//     * AdditionalParameters - Structure - Additional parameters passed earlier in the procedure 
//                                 "Start fiscalization with a payment card".
//   Text - String - The text of the slip receipt that will be displayed in the body of the fiscal receipt can be redefined
//   StandardProcessing - Boolean - If the message is False, then you need to generate a slip-check yourself
//                          by filling in the array "Parametersfiscalization check.Positychek".
Procedure CreateSlipReceiptTemplate(Type, DataForTemplate, Text, StandardProcessing) Export
	
EndProcedure

#EndRegion


#Region ObsoleteProceduresAndFunctions

// Deprecated: no longer in use
// Handler for the event for receiving the client ID for the Work site.
//
// Parameters:
//  ClientID - String, Undefined - client ID
//  StandardProcessing - Boolean
//
Procedure ClientIDForWorkplace(ClientID, StandardProcessing) Export
	
EndProcedure

// Deprecated: for backward compatibility.
Procedure ProcessEvent() Export
	
EndProcedure

// Process the connected hardware event.
// 
// Parameters:
//  Event - Name of the external event 
//  Data - External event data
//  StandardProcessing - Boolean - if False, no further processing is required 
//
Procedure ProcessConnectedHardwareEvent(Event, Data, StandardProcessing) Export    
	
EndProcedure

#EndRegion

#EndRegion