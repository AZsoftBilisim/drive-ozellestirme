#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	OnReadCreateAtServer();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ToScheduleGoodsUnlockOnChange(Item)
	
	Items.GroupDuration.Visible = DurationOfQualityControlWeSee(ThisObject);
	If Not Object.ToScheduleGoodsUnlock Then
		Object.QualityControlDuration = 0;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	ThisIsInputControl = Object.Ref = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	
	ReadOnly = ReadOnly Or ThisIsInputControl;
	Items.ToScheduleGoodsUnlock.Visible = Not ThisIsInputControl;
	Items.GroupDuration.Visible = DurationOfQualityControlWeSee(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Function DurationOfQualityControlWeSee(Form)
	
	Return Not Form.ThisIsInputControl And Form.Object.ToScheduleGoodsUnlock;
	
EndFunction

#EndRegion