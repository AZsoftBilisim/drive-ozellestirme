
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	BudgetProfile = Parameters.BudgetProfile;
	BeginOfPeriod = Parameters.BeginOfPeriod;
	ActualDataLimit = Parameters.ActualDataLimit;
	DefaultDataFactBorder = Catalogs.BudgetProfiles.BorderOfActualDataByBudgetType(BudgetProfile, BeginOfPeriod);
	TitleText = NStr("vi = 'Sử dụng ranh giới dữ liệu thực tế mặc định (%1)';
					|ru = 'Использовать границу факт.данных по-умолчанию (%1)';
					|en = 'Use the default actual data limit (%1)'; fa = 'Use the default actual data limit (%1)';
					|it = 'Utilizzare il limite dei dati attuali da impostazione predefinita (%1)';
					|pl = 'Używaj granicy danych faktycznych domyślnie (%1)';
					|tr = 'Varsayılana göre gerçek veri limitini kullan (%1)'");
	TitleText = StringFunctionsClientServer.SubstituteParametersToString(TitleText, Format(DefaultDataFactBorder, "DLF=D"));
	Items.UseByDefault.ChoiceList[0].Presentation = TitleText;
	
	If ActualDataLimit <> DefaultDataFactBorder Then
		OptionOfActualDataLimit = 1;
	EndIf;
	
	FormControl(ThisForm);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOfTheFactBoundaryTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = False;
	RegulationOnServer(Direction);
	
EndProcedure

&AtClient
Procedure CompleteEditing(Command)
	
	If CheckFilling() Then
		If OptionOfActualDataLimit = 1 Then
			Close(ActualDataLimit);
		Else
			Close(DefaultDataFactBorder);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure VariantOnChange(Item)
	
	FormControl(ThisForm);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure RegulationOnServer(Direction)
	
	If ValueIsFilled(BudgetProfile) Then
		Periodicity = Common.ObjectAttributeValue(BudgetProfile, "Periodicity");
	Else
		Periodicity = Enums.Periodicity.Month;
	EndIf;
	
	If Direction > 0 Then
		
		NewDate = BegOfDay(WorkingWithClientServerPeriods.PeriodEndDate_(ActualDataLimit, Periodicity));
		If NewDate > ActualDataLimit Then
			ActualDataLimit = NewDate;
			Return;
		EndIf;
		
	Else
		
		NewDate = BegOfDay(WorkingWithClientServerPeriods.BeginningDateOfPeriod(ActualDataLimit, Periodicity) - 1);
		If NewDate < ActualDataLimit Then
			ActualDataLimit = NewDate;
			Return;
		EndIf;
		
	EndIf;
	
	ActualDataLimit = WorkingWithClientServerPeriods.PeriodEndDate_(
		WorkingWithClientServerPeriods.AddInterval(NewDate, Periodicity, Direction), Periodicity);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	Form.Items.DateOfTheFactBoundary.Enabled = Form.OptionOfActualDataLimit;
	
EndProcedure

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
