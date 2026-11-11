#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	AutocompletionOfConversionRatio = Parameters.AutocompletionOfConversionRatio;
	RequestCoefficient = Parameters.RequestCoefficient;
	CategoryUnitOfMeasurement = Parameters.CategoryUnitOfMeasurement;
	
	If AutocompletionOfConversionRatio Then
		Items.SetConversionRatio.Visible = True;
		Items.SetConversionRatio.Enabled = True;
		Items.AutoRecalculationGroup.Visible = True;
		Items.CoefficientInputGroup.Visible = False;
		Items.GroupWhenSelectingItemWithDifferentUNITS.Visible = False;
	EndIf;
		
	If RequestCoefficient Then
		Items.SetConversionRatio.Visible = True;
		Items.SetConversionRatio.Enabled = True;
		Items.AutoRecalculationGroup.Visible = False;
		Items.CoefficientInputGroup.Visible = True; 
		Items.GroupWhenSelectingItemWithDifferentUNITS.Visible = Parameters.ThereAreDifferentUnits;
	EndIf;
		
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ToBegin(Command)
	
	If RequestCoefficient
		And Not ValueIsFilled(ConversionFactor_) Then
		ShowMessageBox(, NStr("vi = 'Chưa đặt hệ số tính lại.';
								|ru = 'Не задан коэффициент пересчета.';
								|en = 'Conversion ratio is not set.'; fa = 'Conversion ratio is not set.';
								|it = 'Conversion ratio is not set.';
								|pl = 'Conversion ratio is not set.';
								|tr = 'Dönüştürme oranı belirtilmedi.'"));
	Else
		Result = New Structure;
		Result.Insert("ConversionFactor_", ConversionFactor_);
		Close(Result);
	EndIf;
	
EndProcedure

#EndRegion