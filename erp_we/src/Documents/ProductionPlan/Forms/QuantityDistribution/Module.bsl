
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	NumberOfPeriods = Parameters.NumberOfPeriods;
	
	Operation = "AccordingToRateOfRelease";
	Repetition = 1;
	OptionOfDistributionAccordingToRateOfRelease = "SelectedRows";
	
	OptionOfDistributionByPeriod = "Proportionally";
	
	HintRateOfRelease = NStr("vi = 'Ví dụ, 10 sản phẩm bội số 4 sẽ được phân bổ theo các kỳ là: 4, 4, 2.';
							|ru = 'Например, 10 шт изделий кратно 4 будет распределено по периодам как: 4, 4, 2.';
							|en = 'For example, 10 items multiple of 4 will be allocated to periods as 4, 4, 2.'; fa = 'For example, 10 items multiple of 4 will be allocated to periods as 4, 4, 2.';
							|it = 'Например, 10 шт изделий кратно 4 будет распределено по периодам как: 4, 4, 2.';
							|pl = 'For example, 10 items multiple of 4 will be allocated to periods as 4, 4, 2.';
							|tr = 'Örneğin, 10 adet nihai ürün 4''ün katları şeklinde dönemlere ayrılacaktır: 4, 4, 2.'");
	TooltipAllocation = NStr("vi = 'Ví dụ, 10 chiếc sản phẩm trong 5 kỳ sẽ được phân bổ theo 2 chiếc trong mỗi kỳ với tỷ lệ phân bổ.';
							|ru = 'Например, 10 шт изделий на 5 периодов будет распределено по 2 шт в каждом периоде при пропорциональном распределении.';
							|en = 'For example, 10 items will be allocated to 5 periods as 2 items in each period with proportional allocation.'; fa = 'For example, 10 items will be allocated to 5 periods as 2 items in each period with proportional allocation.';
							|it = 'Например, 10 шт изделий на 5 периодов будет распределено по 2 шт в каждом периоде при пропорциональном распределении.';
							|pl = 'For example, 10 items will be allocated to 5 periods as 2 items in each period with proportional allocation.';
							|tr = 'Örneğin 5 dönem için 10 adet ürün her dönemde 2 adet olacak şekilde orantısal dağıtımla dağıtılacaktır.'");
	
	// Reading the saved previous selection
	DistributionParameters = Common.FormDataSettingsStorageLoad(
		String(Scenario.UUID()),
		"DistributionParameters");
	If TypeOf(DistributionParameters) = Type("Structure") Then
		FillPropertyValues(ThisObject, DistributionParameters,, "Shares");
		
		If DistributionParameters.Property("Shares") And OptionOfDistributionByPeriod <> "Proportionally" Then
			
			For Each Share In DistributionParameters.Shares Do
			
				NewRow = Shares.Add();
				NewRow.Share = Share;
			
			EndDo;
			
		EndIf; 
	EndIf;
	
	FillInShares(Shares, NumberOfPeriods);
	
	FillIn_Products(Parameters.StorageAddressDistribution);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetAccessibilityVisibility();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OperationOnChange(Item)
	SetAccessibilityVisibility();
EndProcedure

&AtClient
Procedure AllocationOptionOnChange(Item)
	SetAccessibilityVisibility();
EndProcedure

&AtClient
Procedure NumberOfPeriodsOnChange(Item)
	FillInShares(Shares, NumberOfPeriods);
EndProcedure

&AtClient
Procedure OptionOfDistributionByPeriodOnChange(Item)
	
	If OptionOfDistributionByPeriod = "Proportionally" Then
		
		Shares.Clear();
		FillInShares(Shares, NumberOfPeriods);
		
	EndIf; 
	
	SetAccessibilityVisibility();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	If Operation = "AccordingToRateOfRelease"
		And OptionOfDistributionAccordingToRateOfRelease = "MultiplicityOfProducts"
		And Items.PagesByIssueRate.CurrentPage = Items.GroupParameters Then
		
		Items.PagesByIssueRate.CurrentPage = Items.MultiplicityGroup;
		SetAccessibilityVisibility();
		
	ElsIf Operation = "ByPeriods"
		And OptionOfDistributionByPeriod = "ByShares"
		And Items.PagesByPeriod.CurrentPage = Items.MainGroup3 Then
		
		Items.PagesByPeriod.CurrentPage = Items.TheGroupSShare;
		SetAccessibilityVisibility();
		
	Else
		
		If Operation = "ByPeriods" And OptionOfDistributionByPeriod = "ByShares" Then
			
			If Shares.Count() = Shares.FindRows(New Structure("Share", 0)).Count() Then
				ShowMessageBox(, NStr("vi = 'Hãy chỉ ra tỷ lệ phân bổ ít nhất cho một kỳ';
										|ru = 'Укажите долю распределения хотя бы для одного периода';
										|en = 'Specify a distribution percentage at least for one period'; fa = 'Specify a distribution percentage at least for one period';
										|it = 'Укажите долю распределения хотя бы для одного периода';
										|pl = 'Specify a distribution percentage at least for one period';
										|tr = 'En az bir dönem için dağıtım payı belirtin'"));
				Return;
			EndIf;
			
		EndIf;
		
		// saving the settings
		DistributionParameters = GenerateAndSaveSettingsOnServer();
		
		Close(DistributionParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	If Operation = "AccordingToRateOfRelease" Then
		Items.PagesByIssueRate.CurrentPage = Items.GroupParameters;
	ElsIf Operation = "ByPeriods" Then
		Items.PagesByPeriod.CurrentPage = Items.MainGroup3;
	EndIf;
	
	SetAccessibilityVisibility();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetAccessibilityVisibility()

	If Operation = "AccordingToRateOfRelease" Then
		
		Items.OperationPages.CurrentPage = Items.PageByIssueRate;
		
		If OptionOfDistributionAccordingToRateOfRelease = "SelectedRows"
			Or Items.PagesByIssueRate.CurrentPage = Items.MultiplicityGroup Then
			Items.FormNext.Title = NStr("vi = 'Phân bổ';
										|ru = 'Распределить';
										|en = 'Allocate'; fa = 'تسهیم';
										|it = 'Распределить';
										|pl = 'Allocate';
										|tr = 'Dağıt'");
		Else
			Items.FormNext.Title = NStr("vi = 'Tiếp theo >';
										|ru = 'Далее >';
										|en = 'Next >'; fa = 'بعدی >';
										|it = 'Avanti >';
										|pl = 'Dalej >';
										|tr = 'İleri >'");
		EndIf;
		
	ElsIf Operation = "ByPeriods" Then
		
		Items.OperationPages.CurrentPage = Items.PageByPeriod;
		
		If OptionOfDistributionByPeriod = "Proportionally"
			Or Items.PagesByPeriod.CurrentPage = Items.TheGroupSShare Then
			Items.FormNext.Title = NStr("vi = 'Phân bổ';
										|ru = 'Распределить';
										|en = 'Allocate'; fa = 'تسهیم';
										|it = 'Распределить';
										|pl = 'Allocate';
										|tr = 'Dağıt'");
		Else
			Items.FormNext.Title = NStr("vi = 'Tiếp theo >';
										|ru = 'Далее >';
										|en = 'Next >'; fa = 'بعدی >';
										|it = 'Avanti >';
										|pl = 'Dalej >';
										|tr = 'İleri >'");
		EndIf;
		
	EndIf; 
	
	If Operation = "ByPeriods"
		And OptionOfDistributionByPeriod = "ByShares" 
		And Items.PagesByPeriod.CurrentPage = Items.TheGroupSShare
		Or Operation = "AccordingToRateOfRelease"
		And OptionOfDistributionAccordingToRateOfRelease = "MultiplicityOfProducts"
		And Items.PagesByIssueRate.CurrentPage = Items.MultiplicityGroup Then
		
		Items.FormBack.Visible = True;
		
	Else
		Items.FormBack.Visible = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInShares(Shares, NumberOfPeriods)
	
	PeriodPresentation = NStr("vi = 'kỳ';
								|ru = 'период';
								|en = 'period'; fa = 'period';
								|it = 'период';
								|pl = 'period';
								|tr = 'dönem'");
	
	If NumberOfPeriods = Shares.Count() Then
		
		For Each TSRow In Shares Do
			
			Period = Shares.IndexOf(TSRow) + 1;
			TSRow.Period = Period;
			TSRow.Presentation = String(Period) + " " + PeriodPresentation;
		EndDo;
	Else
	
		Shares.Clear();
		
		For Period =1 To NumberOfPeriods Do
			
			NewRow = Shares.Add();
			
			NewRow.Period = Period;
			NewRow.Presentation = String(Period) + " " + PeriodPresentation;
			NewRow.Share = 1;
		EndDo;
	
	EndIf; 

EndProcedure

&AtServer
Procedure FillIn_Products(StorageAddressDistribution)
	
	Products_1 = GetFromTempStorage(StorageAddressDistribution);// ValueTable
	Products_1.GroupBy("Products, Characteristic");
	
	ProductsMultiplicity.Load(Products_1);
	
EndProcedure

&AtServer
Function GenerateAndSaveSettingsOnServer()
	
	DistributionParameters = New Structure;
	DistributionParameters.Insert("Operation", Operation);
	
	DistributionParameters.Insert("OptionOfDistributionAccordingToRateOfRelease", OptionOfDistributionAccordingToRateOfRelease);
	DistributionParameters.Insert("Repetition", Repetition);
	
	StorageAddress = "";
	If OptionOfDistributionAccordingToRateOfRelease = "MultiplicityOfProducts" Then
		StorageAddress = PutToTempStorage(ProductsMultiplicity.Unload(,"Products, Characteristic, Repetition"));
	EndIf;
	
	DistributionParameters.Insert("StorageAddressMultiplicity", StorageAddress);
	
	DistributionParameters.Insert("NumberOfPeriods", NumberOfPeriods);
	DistributionParameters.Insert("OptionOfDistributionByPeriod", OptionOfDistributionByPeriod);
	DistributionParameters.Insert("RoundingPrecision", RoundingPrecision);
	DistributionParameters.Insert("Shares", Shares.Unload(,"Share").UnloadColumn("Share"));
	
	// We save the settings in the context of the scenario
	
	Common.FormDataSettingsStorageSave(
		String(Scenario.UUID()),
		"DistributionParameters",
		DistributionParameters);
	
	Return DistributionParameters;

EndFunction
 
#EndRegion
