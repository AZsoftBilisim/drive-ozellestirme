// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	References.Load(GetFromTempStorage(Parameters.ReferenceAddress));
	ReferenceAddress = "";
	
	For Each OrderLine_2 In References Do
		If Not ValueIsFilled(OrderLine_2.Time) Then
			OrderLine_2.Time = GoodsDeliveryClientServer.PresentationOfDeliveryTime(OrderLine_2.TimeFrom,OrderLine_2.TimeTo); 	
		EndIf;	
	EndDo;
	
	UnitOfMeasureForWeight = Constants.UnitOfMeasureForWeight.Get();
	UnitOfMeasureForVolume = Constants.UnitOfMeasureForVolume.Get();
	
	TitleText = NStr("vi = 'Khối lượng, %UnitOfMeasureForVolume%';
					|ru = 'Объем, %UnitOfMeasureForVolume%';
					|en = 'Volume, %UnitOfMeasureForVolume%'; fa = 'Volume, %UnitOfMeasureForVolume%';
					|it = 'Volume, %UnitOfMeasureForVolume%';
					|pl = 'Objętość, %UnitOfMeasureForVolume%';
					|tr = 'Hacim, %UnitOfMeasureForVolume%'");
	TitleText = StrReplace(TitleText, "%UnitOfMeasureForVolume%", String(UnitOfMeasureForVolume));
	Items.ReferencesVolumeM3.Title = TitleText;
		
	TitleText = NStr("vi = 'Trọng lượng, %UnitOfMeasureForWeight%';
					|ru = 'Вес, %UnitOfMeasureForWeight%';
					|en = 'Weight, %UnitOfMeasureForWeight%'; fa = 'Weight, %UnitOfMeasureForWeight%';
					|it = 'Peso, %UnitOfMeasureForWeight%';
					|pl = 'Waga, %UnitOfMeasureForWeight%';
					|tr = 'Ağırlık, %UnitOfMeasureForWeight%'");
	TitleText = StrReplace(TitleText, "%UnitOfMeasureForWeight%", String(UnitOfMeasureForWeight));
	Items.ReferencesWeight.Title = TitleText;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If ReferenceAddress <> ""
		And Not Exit Then
		
		Structure = New Structure("ReferenceAddress", ReferenceAddress);
		NotifyChoice(Structure);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	PlaceOrdersInVault();
	Close(DialogReturnCode.OK);
	
EndProcedure

&AtClient
Procedure SetAll(Command)
	
	For Each Page1 In References Do
		Page1.Selected = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearAllIetmsCommand(Command)
	
	For Each Page1 In References Do
		Page1.Selected = False;
	EndDo;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure PlaceOrdersInVault();
	// At least one instruction must remain in the original line of the route point
	If References.FindRows(New Structure("Selected",False)).Count() > 0
		  And References.FindRows(New Structure("Selected",True)).Count() > 0 Then
		TableOfSelected = FormAttributeToValue("References").Copy(New Structure("Selected", True));
		ReferenceAddress = PutToTempStorage(TableOfSelected, UUID);
	EndIf;
EndProcedure

#EndRegion
