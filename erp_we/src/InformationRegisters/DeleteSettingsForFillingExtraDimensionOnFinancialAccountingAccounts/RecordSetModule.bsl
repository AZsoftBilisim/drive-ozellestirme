#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	For Each SetRecord In ThisObject Do
		If Not IsBlankString(SetRecord.ExpressionOfExtdimensionFilling1) Then
			SetRecord.ExpressionOfExtdimensionFilling1 = StrReplace(SetRecord.ExpressionOfExtdimensionFilling1, "_", ".");
		EndIf;
		If Not IsBlankString(SetRecord.ExpressionOfExtdimensionFilling2) Then
			SetRecord.ExpressionOfExtdimensionFilling2 = StrReplace(SetRecord.ExpressionOfExtdimensionFilling2, "_", ".");
		EndIf;
		If Not IsBlankString(SetRecord.ExpressionOfExtdimensionFilling3) Then
			SetRecord.ExpressionOfExtdimensionFilling3 = StrReplace(SetRecord.ExpressionOfExtdimensionFilling3, "_", ".");
		EndIf;
		If Not ValueIsFilled(SetRecord.SpecifiedValueIsExtdimension1) Then
			SetRecord.SpecifiedValueIsExtdimension1 = Undefined;
		EndIf;
		If Not ValueIsFilled(SetRecord.SpecifiedValueIsExtdimension2) Then
			SetRecord.SpecifiedValueIsExtdimension2 = Undefined;
		EndIf;
		If Not ValueIsFilled(SetRecord.SpecifiedValueIsExtdimension3) Then
			SetRecord.SpecifiedValueIsExtdimension3 = Undefined;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndIf