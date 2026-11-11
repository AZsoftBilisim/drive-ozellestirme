
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("SpecifyProductionDate", SpecifyProductionDate) Then
		
		SpecifyProductionDate = False;
		
		ValidUntil_ = Parameters.ValidUntil_;
		
		If Parameters.Property("UseProductionDate") Then
			ProductionDate = Parameters.ProductionDate;
		EndIf;
		
		ExpirationDate_                  = Parameters.ExpirationDate_;
		ShelfLifeUnitOfMeasure = Parameters.ShelfLifeUnitOfMeasure;
		
		Items.ProductionDate.Format               = Parameters.DateFormat;
		Items.ProductionDate.EditFormat = Parameters.DateFormat;
		
	Else
		
		ValidUntil_ = Parameters.ProductionDate;
		
		Items.ValidUntil_.Title = NStr("vi = 'Ngày sản xuất';
										|ru = 'Дата производства';
										|en = 'Production date'; fa = 'تاریخ تولید';
										|it = 'Data di produzione';
										|pl = 'Data produkcji';
										|tr = 'Üretim tarihi'");
		
		Items.GroupProductionDate.Visible = False;
		
	EndIf;
	
	If Not ValueIsFilled(ValidUntil_) Then
		ValidUntil_ = BegOfDay(CurrentSessionDate());
	EndIf;
	
	Items.ValidUntil_.SelectedDates.Clear();
	Items.ValidUntil_.SelectedDates.Add(ValidUntil_);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ValidUntil_Selection(Item, SelectedDate)
	
	ChoiceData = ResultSelectionData();
	
	Close(ChoiceData);
	
EndProcedure

&AtClient
Procedure ProductionDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ProductsClientServer.RecalculateSeriesDate(ProductionDate);
	
	CalculateValidUntil();
	
EndProcedure

&AtClient
Procedure ExpirationDate_OnChange(Item)
	
	CalculateValidUntil();
	
EndProcedure

&AtClient
Procedure ShelfLifeUnitOfMeasureOnChange(Item)
	
	CalculateValidUntil();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ChoiceData = ResultSelectionData();
	
	Close(ChoiceData);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CalculateValidUntil()
	
	CalculatedValidUntil = ProductsClientServer.ValidUntilDateOfProduction(ProductionDate, ExpirationDate_,
							ShelfLifeUnitOfMeasure);
	
	If Not ValueIsFilled(CalculatedValidUntil) Then
		Return;
	EndIf;
	
	ValidUntil_ = CalculatedValidUntil;
	
	Items.ValidUntil_.SelectedDates.Clear();
	Items.ValidUntil_.SelectedDates.Add(ValidUntil_);
	
EndProcedure

&AtClient
Function ResultSelectionData()
	
	ChoiceData = New Structure;
	
	If SpecifyProductionDate Then
		ChoiceData.Insert("ProductionDate", ValidUntil_);
	Else
		ChoiceData.Insert("ValidUntil_",          ValidUntil_);
		ChoiceData.Insert("ProductionDate", ProductionDate);
	EndIf;
	
	Return ChoiceData;
	
EndFunction

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
	If Item.Name = "sh_ShamsiInput_F_ProductionDate" Then
		ProductionDateOnChange(Items.ProductionDate);
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
