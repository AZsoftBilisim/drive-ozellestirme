#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

// This procedure initializes the device parameters.
//
Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	If IsNew() Then
		Parameters = New ValueStorage(New Structure());
	EndIf;
	
EndProcedure // Before recording()

// At record
//
Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

EndProcedure

// The procedure cleans up the details that should not be copied.
// The following details are cleared when copying:
// "Parameters" - device parameters are reset to Undefined;
// "Name" - is set different from the original name.
Procedure OnCopy(CopiedObject)
	
	DeviceIsInUse = True;
	Parameters = Undefined;
	
	Description = NStr("vi = '%Description% (bản sao)';
						|ru = '%Description% (копия)';
						|en = '%Description% (copy)'; fa = '%Description% (copy)';
						|it = '%Description% (copia)';
						|pl = '%Description% (kopia)';
						|tr = '%Description% (kopya)'");
	Description = StrReplace(Description, "%Description%", CopiedObject.Description);
	
EndProcedure

// The procedure checks whether the name of the directory element is unique
// for this computer.
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
 
	If Not IsBlankString(Description) Then
		Query = New Query("
		|SELECT
		|    1
		|FROM
		|    Catalog.Peripherals AS Peripherals
		|WHERE
		|    Peripherals.Description = &Description
		|    AND Peripherals.Workplace = &Workplace
		|    AND Peripherals.Ref <> &Ref
		|");

		Query.SetParameter("Description", Description);
		Query.SetParameter("Workplace", Workplace);
		Query.SetParameter("Ref"      , Ref);
		
		If Not Query.Execute().IsEmpty() Then
			CommonCEL.MessageToUser(NStr("vi = 'Hãy chỉ định tên gọi đơn trị.';
										|ru = 'Укажите уникальное наименование.';
										|en = 'Specify a unique name.'; fa = 'Specify a unique name.';
										|it = 'Indicare denominazione univoca.';
										|pl = 'Podaj unikalną nazwę';
										|tr = 'Benzersiz tanımı belirt.'"), ThisObject, , , Cancel);
		EndIf;
	EndIf;
	
	If EquipmentType <> Enums.PeripheralTypes.CREWithDataTransfer 
		And EquipmentType <> Enums.PeripheralTypes.FiscalCashRegisters 
		And EquipmentType <> Enums.PeripheralTypes.ReceiptPrinter Then   
		ElementIndex = CheckedAttributes.Find("Organization");
		If ElementIndex <> Undefined Then
			CheckedAttributes.Delete(ElementIndex);
		EndIf;
	EndIf;
	
	If EquipmentType <> Enums.PeripheralTypes.CREWithDataTransfer Then
		ElementIndex = CheckedAttributes.Find("MethodOfFormatLogicalControl");
		If ElementIndex <> Undefined Then
			CheckedAttributes.Delete(ElementIndex);
		EndIf;
	EndIf;
	
EndProcedure // Processing of the Fill check()

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If CommonCEL.FormatLogicalControlIsUsed() Then
		If Not ValueIsFilled(MethodOfFormatLogicalControl) Then
			MethodOfFormatLogicalControl = Enums.MethodsOfFormatLogicalControl.DivideRows;
			AllowableDiscrepancyOfFormatLogicalControl = 0.01;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf