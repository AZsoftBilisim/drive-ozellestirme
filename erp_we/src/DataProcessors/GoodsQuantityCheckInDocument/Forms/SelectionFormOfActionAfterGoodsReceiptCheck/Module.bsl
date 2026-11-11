
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	UsedDelivery25 = GoodsDeliveryClientServer.UsedDelivery25();
	
	WarehouseDocument = Parameters.WarehouseDocument;
	ShipmentUnderTransportationJob = Parameters.ShipmentUnderTransportationJob;
	If UsedDelivery25 Then
		Trip = Parameters.TransportationJob;
	Else
		TransportationJob = Parameters.TransportationJob;
	EndIf;
	
	Items.TransportationJob.Visible = Not UsedDelivery25;
	
	OptionOfNoteCheckEnd = "SetStatusChecked";
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TransportationJobStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure("WarehouseDocument", WarehouseDocument);
	
	OpenForm("Document.GoodsIssueNote.Form.TransportationJobChoiceForm",
		FormParameters, Item,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If OptionOfNoteCheckEnd = "SetTheStatusForShipment"
		And ShipmentUnderTransportationJob
		And Not ValueIsFilled(TransportationJob)
		And Not UsedDelivery25 Then
		
		MessageText = NStr("vi = 'Không có nhiệm vụ vận chuyển được lựa chọn.';
							|ru = 'Не выбрано задание на перевозку.';
							|en = 'No itinerary is selected.'; fa = 'No itinerary is selected.';
							|it = 'Nessun task di spedizione selezionato.';
							|pl = 'Nie wybrano zadanie na transport.';
							|tr = 'Taşıma planı seçilmedi.'");
		CommonClientServer.MessageToUser(MessageText, Undefined, "TransportationJob");
		
		Return;
		
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("OptionOfNoteCheckEnd", OptionOfNoteCheckEnd);
	NotificationParameters.Insert("DontAskAgain", DontAskAgain);
	If UsedDelivery25 Then
		NotificationParameters.Insert("TransportationJob", Trip);
	Else
		NotificationParameters.Insert("TransportationJob", TransportationJob);
	EndIf;
	
	Notify("OptionToCompleteOrderVerificationIsSet", NotificationParameters, ThisForm.FormName);
	
	Close(DialogReturnCode.OK);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField      = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransportationJob.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("OptionOfNoteCheckEnd");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "SetTheStatusForShipment";
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("ShipmentUnderTransportationJob");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TransportationJob");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure

#EndRegion
