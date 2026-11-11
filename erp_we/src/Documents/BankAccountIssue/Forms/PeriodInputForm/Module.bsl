
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	BasisIndicator = Parameters.BasisIndicator;
	
	PeriodPosition = StrFind(TrimAll(Parameters.PeriodIndicator),".");
	PositionOfYear = StrFind(Mid(TrimAll(Parameters.PeriodIndicator), PeriodPosition + 1), ".") + PeriodPosition;

	TaxPeriodicity = Left(TrimAll(Parameters.PeriodIndicator), PeriodPosition - 1);
	StringPeriodNumber = Mid(TrimAll(Parameters.PeriodIndicator), PeriodPosition + 1, PositionOfYear - PeriodPosition - 1);
	StringYearOfPeriod = Mid(TrimAll(Parameters.PeriodIndicator), PositionOfYear + 1);
	
	If StrFind("TP, ZD", BasisIndicator) > 0 Then
		If StrLen(TaxPeriodicity) = 2
		   And StrLen(StringPeriodNumber) = 2 
		   And StrLen(StringYearOfPeriod) = 4
		   And StringFunctionsClientServer.OnlyNumbersInString(TaxPeriodicity)
		   And StringFunctionsClientServer.OnlyNumbersInString(StringPeriodNumber)
		   And StringFunctionsClientServer.OnlyNumbersInString(StringYearOfPeriod) Then
			IndicatorDate = Date(Number(StringYearOfPeriod), Number(StringPeriodNumber), Number(TaxPeriodicity));
		EndIf;
	EndIf;
	
	PeriodNumber = StringPeriodNumber;
	PeriodYear = StringYearOfPeriod;
	
	If Parameters.PeriodIndicator = "0" Then
		TaxPeriodicity = "0";
	ElsIf StrFind("MS,KV,PL_,GD", TaxPeriodicity) = 0 Then
		TaxPeriodicity = "-";
	EndIf;
	
	FormItemsManagement();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If TaxPeriodicity = "0"
		Or IsBlankString(TaxPeriodicity) Then
		
		NotCheckedAttributeArray.Add("PeriodNumber");
		NotCheckedAttributeArray.Add("PeriodYear");
		NotCheckedAttributeArray.Add("IndicatorDate");
		
	ElsIf StrFind("MS,KV,PL_,GD", TaxPeriodicity) > 0 Then
		NotCheckedAttributeArray.Add("IndicatorDate");
	
		If TaxPeriodicity = "GD" Then
			NotCheckedAttributeArray.Add("PeriodNumber");
		EndIf;
	
	ElsIf TaxPeriodicity = "-" Then
		NotCheckedAttributeArray.Add("PeriodNumber");
		NotCheckedAttributeArray.Add("PeriodYear");
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TaxPeriodicityOnChange(Item)
	
	FormItemsManagement();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	If CheckFilling() Then
	
		If TaxPeriodicity = "-" Then
			PeriodIndicator = String(Format(IndicatorDate,"DLF=D"));
			
		ElsIf TaxPeriodicity = "0" Then
			PeriodIndicator = "0";
			
		Else
			PeriodIndicator = TaxPeriodicity 
				+ "." 
				+ ?(StrLen(TrimAll(PeriodNumber)) = 1, "0" + PeriodNumber, PeriodNumber)
				+ "." 
				+ StrReplace(String(PeriodYear), Chars.NBSp, "");
				
		EndIf;
		
		Close(PeriodIndicator);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Modified = False;
	Close();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region FormItemsManagement

&AtServer
Procedure FormItemsManagement()

	If Not IsBlankString(TaxPeriodicity)
	   And StrFind("MS,KV,PL_,GD", TaxPeriodicity) > 0 Then
		
		YearOfPeriodVisibility = True;
		DateOfVisibilityIndicator = False;
		
		If TaxPeriodicity = "MS" Then
			If PeriodNumber < 1 Or PeriodNumber > 12 Then
				PeriodNumber = 1;
			EndIf;
			Items.PeriodNumber.MinValue = 1;
			Items.PeriodNumber.MaxValue = 12;
			PeriodNumberVisibility = True;
			
		ElsIf TaxPeriodicity = "KV" Then
			If PeriodNumber < 1 Or PeriodNumber > 4 Then
				PeriodNumber = 1;
			EndIf;
			Items.PeriodNumber.MinValue = 1;
			Items.PeriodNumber.MaxValue = 4;
			PeriodNumberVisibility = True;
			
		ElsIf TaxPeriodicity = "PL_" Then
			If PeriodNumber < 1 Or PeriodNumber > 2 Then
				PeriodNumber = 1;
			EndIf;
			Items.PeriodNumber.MinValue = 1;
			Items.PeriodNumber.MaxValue = 2;
			PeriodNumberVisibility = True;
			
		ElsIf TaxPeriodicity = "GD" Then
			PeriodNumber = 0;
			PeriodNumberVisibility = False;
			
		EndIf;
		
		If PeriodYear = 0 Then
			PeriodYear = Year(CurrentSessionDate());
		EndIf;
		
	ElsIf TaxPeriodicity = "-" Then
		PeriodNumberVisibility = False;
		YearOfPeriodVisibility = False;
		DateOfVisibilityIndicator = True;
	Else
		PeriodNumberVisibility = False;
		YearOfPeriodVisibility = False;
		DateOfVisibilityIndicator = False;
	EndIf;
	
	If Items.PeriodNumber.Visible <> PeriodNumberVisibility Then
		Items.PeriodNumber.Visible = PeriodNumberVisibility;
	EndIf;
	If Items.PeriodYear.Visible <> YearOfPeriodVisibility Then
		Items.PeriodYear.Visible = YearOfPeriodVisibility;
	EndIf;
	If Items.IndicatorDate.Visible <> DateOfVisibilityIndicator Then
		Items.IndicatorDate.Visible = DateOfVisibilityIndicator;
	EndIf;
	
EndProcedure



#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
