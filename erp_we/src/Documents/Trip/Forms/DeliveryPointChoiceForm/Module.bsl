// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not IsBlankString(Parameters.FormCaption) Then
		Title = Parameters.FormCaption;
	EndIf;
	
	Carrier = Parameters.Carrier;
	DeliveryPoint = Parameters.DeliveryPoint;
	DeliveryZone = Parameters.DeliveryZone;
	
	Recipient = Parameters.Recipient;
	RecipientPoint = Parameters.RecipientPoint;
	Recipient_Area = Parameters.Recipient_Area;
	
	SelectOnlyRecipient = Parameters.SelectOnlyRecipient;
	
	If Parameters.SelectOnlyCarrier Then
		
		Items.Recipient.Visible = False;
		Items.RecipientPoint.Visible = False;
		Items.Recipient_Area.Visible = False;
		
	ElsIf Parameters.SelectOnlyRecipient Then
		
		Items.Carrier.Visible = False;
		Items.DeliveryPoint.Visible = False;
		Items.DeliveryZone.Visible = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If SelectOnlyRecipient Then
		
		NotCheckedAttributes = CommonClientServer.ValueInArray("Carrier");
		Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributes);
		
	EndIf;
	
	If Carrier = Recipient Then
		
		MessageText = NStr("vi = 'Thông tin của người nhận và người vận chuyển trùng nhau, không thể lập vận chuyển.';
							|ru = 'Совпадают данные получателя и перевозчика, оформление доставки невозможно.';
							|en = 'The details of the recipient and the carrier match. Cannot register the delivery.'; fa = 'The details of the recipient and the carrier match. Cannot register the delivery.';
							|it = 'The details of the recipient and the carrier match. Cannot register the delivery.';
							|pl = 'The details of the recipient and the carrier match. Cannot register the delivery.';
							|tr = 'Alıcı ve taşıyıcı verileri eşleşiyor, teslimat oluşturma mümkün değil.'");
		Common.MessageToUser(MessageText,,,, Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CarrierOnChange(Item)
	
	If Carrier.IsEmpty() Then
		
		DeliveryPoint = PredefinedValue("Catalog.DeliveryPoints.EmptyRef");
		DeliveryZone = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
		
	Else
		
		CarrierOnChangeServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeliveryPointOnChange(Item)
	
	If DeliveryPoint.IsEmpty() Then
		
		DeliveryZone = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
		
	Else
		
		DeliveryZone = DeliveryPointArea(DeliveryPoint);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecipientPointOnChange(Item)
	
	If RecipientPoint.IsEmpty() Then
		
		Recipient_Area = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
		
	Else
		
		Recipient_Area = DeliveryPointArea(RecipientPoint);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Result = New Structure;
	
	Result.Insert("Carrier", Carrier);
	Result.Insert("DeliveryPoint", DeliveryPoint);
	Result.Insert("DeliveryZone", DeliveryZone);
	
	Result.Insert("Recipient", Recipient);
	Result.Insert("RecipientPoint", RecipientPoint);
	Result.Insert("Recipient_Area", Recipient_Area);
	
	Close(Result);
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function DeliveryPointArea(Val Point)
	
	Return Common.ObjectAttributeValue(Point, "DeliveryZone");
	
EndFunction

#Region EventHandlersForFormHeaderElementsAuxiliary

&AtServer
Procedure CarrierOnChangeServer()
	
	PointData_ = Catalogs.DeliveryPoints.DeliveryPointInformationMain(Carrier);
	DeliveryPoint = PointData_.DeliveryPoint;
	DeliveryZone = PointData_.DeliveryZone;
	
EndProcedure

#EndRegion

#EndRegion