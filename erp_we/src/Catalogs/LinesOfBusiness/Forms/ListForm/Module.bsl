
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CommonClientServer.SetDynamicListParameter(List, "OnAccounts", NStr("vi = 'trong tài khoản ngân hàng và quỹ tiền mặt';
																		|ru = 'на счетах и в кассах';
																		|en = 'on accounts and on cash accounts'; fa = 'on accounts and on cash accounts';
																		|it = 'nei conti e nelle casse';
																		|pl = 'na rachunkach i w kasach';
																		|tr = 'hesaplarda ve kasalarda'"));
	CommonClientServer.SetDynamicListParameter(List, "ByCorrespondence", NStr("vi = 'trao đổi liên lạc';
																				|ru = 'по корреспонденции';
																				|en = 'by correspondence'; fa = 'by correspondence';
																				|it = 'per corrispondenza';
																				|pl = 'wg korespondencji';
																				|tr = 'Muhabire göre'"));
	
	Items.CashManagement.Visible = Not GetFunctionalOption("TradeManagement");

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StatusOnChange(Item)
	StatusChangedOnServer();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure StatusChangedOnServer()
	
	CommonClientServer.SetDynamicListFilterItem(List, "Status", Status, DataCompositionComparisonType.Equal,, ValueIsFilled(Status));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion
