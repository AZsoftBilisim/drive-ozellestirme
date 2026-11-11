
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("Template")
	 Or Not Parameters.Property("Description", TemplateText) Then
		MessageText = NStr("vi = 'Không cho phép mở trực tiếp biểu mẫu này. Để mở biểu mẫu, có thể sử dụng lệnh ""Xem biểu mẫu tài liệu"" trong biểu mẫu tùy chỉnh khuôn mẫu nhập các chỉ tiêu phi tài chính.';
							|ru = 'Непосредственное открытие этой формы не предусмотрено. Для открытия формы можно воспользоваться командой ""Просмотреть форму документа"" в форме настройки шаблона ввода нефинансовых показателей.';
							|en = 'Application cannot open this form explicitly. It opens implicitly when you select ""View document form"" command in the Non-financial item template configuration form.'; fa = 'Application cannot open this form explicitly. It opens implicitly when you select ""View document form"" command in the Non-financial item template configuration form.';
							|it = 'L''apertura diretta di questo modulo non è prevista. Per aprire un modulo è possibile utilizzare il comando ""Visualizza modulo del documento"" nel modulo dell''impostazione di modello di inserimento degli indicatori non finanziari.';
							|pl = 'Bezpośrednie otwarcie tego formularza nie jest przewidziane. Aby otworzyć formularz, możesz użyć polecenia ""Zobacz formularz dokumentu"" w postaci ustawień szablonu wprowadzania wskaźników niefinansowych.';
							|tr = 'Bu formun doğrudan açılması sağlanamadı. Formun açılması için finansal olmayan öğe girişi ayarları şablonu formunda yer alan ""Belge formunu göster"" komutundan faydalanabilirsiniz.'");
		Raise MessageText;
	EndIf;
	
	TemplateStructure = GetFromTempStorage(Parameters.Template);
	
	CurrentSessionDate = CurrentSessionDate();
	PeriodParameters_ = New Structure("BeginOfPeriod, PeriodEnding", 
										BegOfYear(CurrentSessionDate), EndOfYear(CurrentSessionDate));
	InputDescriptionStructure = Documents.SetValuesForNonFinancialItems.DescriptionStructureOfInputDocumentFields(
		Enums.OperationKindsOfSettingOfNonFinancialItemValues.EnterValuesFromTemplate,
		Undefined,
		TemplateStructure,
		TemplateStructure.DefaultComplexTableValues,
		PeriodParameters_);
	
	ReflectTemplateStructure(InputDescriptionStructure);
	
	FormControl(InputDescriptionStructure);
	
	OperationKind = Enums.OperationKindsOfSettingOfNonFinancialItemValues.EnterValuesFromTemplate;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTabularSection

&AtClient
Procedure TabularSectionOnChange(Item)
	
	For Each CrawlString In TabularSection Do
		CrawlString.DocumentRowNumber = TabularSection.IndexOf(CrawlString) + 1;
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ReflectTemplateStructure(InputDescriptionStructure)
	
	If InputDescriptionStructure = Undefined Then
		
		Return;
		
	EndIf;
	
	AddedItems = New Array;
	ItemsToDelete_ = New Array;
	
	Documents.SetValuesForNonFinancialItems.ReflectDocumentHeaderDetails(InputDescriptionStructure, 
																						Items, AddedItems);
	
	IndicatorValues.Clear();
	Documents.SetValuesForNonFinancialItems.ReflectIndicatorsEditedInHeader(InputDescriptionStructure, 
																				Items, AddedItems, IndicatorValues);
	
	Documents.SetValuesForNonFinancialItems.ReflectTabularPartOfDocument(InputDescriptionStructure,
																				Items, ThisObject, AddedItems, ItemsToDelete_);
	
EndProcedure

&AtServer
Procedure FormControl(InputDescriptionStructure)
	
	If InputDescriptionStructure <> Undefined Then
		If InputDescriptionStructure.Period = "Period" Then
			Items.BeginOfPeriod.Title = NStr("vi = 'Kỳ từ';
											|ru = 'Период с';
											|en = 'Period from'; fa = 'دوره از';
											|it = 'Periodo dal';
											|pl = 'Okres od';
											|tr = 'Dönem başı'");
			Items.BeginOfPeriod.Visible = True;
			Items.PagesPeriodEnd.CurrentPage = Items.PeriodEnding;
		ElsIf InputDescriptionStructure.Period = "ValidFrom" Then
			Items.BeginOfPeriod.Title = NStr("vi = 'Có hiệu lực từ';
											|ru = 'Действует с';
											|en = 'Valid from'; fa = 'معتبر از';
											|it = 'In vigore dal';
											|pl = 'Obowiązuje od';
											|tr = 'Geçerlilik başlangıcı'");
			Items.BeginOfPeriod.Visible = True;
			Items.PagesPeriodEnd.CurrentPage = Items.ValidTo;
		Else
			Items.BeginOfPeriod.Visible = False;
			Items.PagesPeriodEnd.CurrentPage = Items.PeriodEndNo;
		EndIf;
	EndIf;
	
	If Items.Indicators.ChildItems.Count()
		And Items.TabularSection.Visible Then
		
		Items.Indicators.Representation = UsualGroupRepresentation.WeakSeparation;
		Items.Indicators.ShowTitle = True;
	
		Items.IndicatorValues.Representation = UsualGroupRepresentation.WeakSeparation;
		Items.IndicatorValues.ShowTitle = True;
		
	Else
		
		Items.Indicators.Representation = UsualGroupRepresentation.None;
		Items.Indicators.ShowTitle = False;
	
		Items.IndicatorValues.Representation = UsualGroupRepresentation.None;
		Items.IndicatorValues.ShowTitle = False;
		
	EndIf;
	
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
