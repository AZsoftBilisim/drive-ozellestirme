
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = ListRequestText(Parameters.Statform);
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	If Parameters.Statform Then
		Items.TaxInvoicedPrice.Visible = True;
		Items.DocumentAmount.Title = NStr("vi = 'Thuế GTGT';
											|ru = 'Сумма НДС';
											|en = 'VAT amount'; fa = 'مبلغ مالیات بر ارزش افزوده';
											|it = 'Importo IVA';
											|pl = 'Wartość VAT';
											|tr = 'KDV tutarı'");
	Else
		Items.TaxInvoicedPrice.Visible = False;
		Items.DocumentAmount.Title = NStr("vi = 'Số tiền';
											|ru = 'Сумма';
											|en = 'Amount'; fa = 'مبلغ';
											|it = 'Importo';
											|pl = 'Wartość';
											|tr = 'Tutar'");
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

&AtServer
Function ListRequestText(Statform)
	
	QueryText =
	"SELECT
	|	DocumentApplicationForImportationOfGoods.Ref AS Ref,
	|	DocumentApplicationForImportationOfGoods.DeletionMark AS DeletionMark,
	|	DocumentApplicationForImportationOfGoods.Number AS Number,
	|	DocumentApplicationForImportationOfGoods.Date AS Date,
	|	DocumentApplicationForImportationOfGoods.Posted AS Posted,
	|	DocumentApplicationForImportationOfGoods.Organization AS Organization,
	|	DocumentApplicationForImportationOfGoods.Counterparty AS Counterparty,
	|	DocumentApplicationForImportationOfGoods.Contract AS Contract,
	|	ISNULL(Companies.LocalAccountingCurrency, VALUE(Catalog.Currencies.EmptyRef))AS DocumentCurrency,
	|	DocumentApplicationForImportationOfGoods.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentApplicationForImportationOfGoods.Comment AS Comment,
	|	DocumentApplicationForImportationOfGoods.DocumentAmount AS DocumentAmount,
	|	DocumentApplicationForImportationOfGoods.PointInTime AS PointInTime
	|FROM
	|	Document.ApplicationForImportationOfGoods AS DocumentApplicationForImportationOfGoods
	|		LEFT JOIN Catalog.Companies AS Companies
	|		ON DocumentApplicationForImportationOfGoods.Organization = Companies.Ref";
	
	
	Return  QueryText;
	
EndFunction

#EndRegion
