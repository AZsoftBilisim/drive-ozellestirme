#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	TableForSettingUpFormationOfTransactions.Load(GetFromTempStorage(Parameters.AddressInTempStorage));
	
	SetConditionalAppearance();
	SetVisibilityAvailability();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	Close(AddressInTemporaryStorageOfChartsOfAccounts());
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	MarkTableElements(True);
EndProcedure

&AtClient
Procedure ClearAllIetmsCommand(Command)
	MarkTableElements(False);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = Items.TableForSettingUpFormationOfTransactionsCheck.Name;

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableForSettingUpFormationOfTransactionsCheck.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableForSettingUpFormationOfTransactions.Enabled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Enabled", False);

	//
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = Items.TableForSettingUpFormationOfTransactionsSettingUpFormationOfInternationalAccountingTransactions.Name;

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableForSettingUpFormationOfTransactionsSettingUpFormationOfInternationalAccountingTransactions.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TableForSettingUpFormationOfTransactionsChartOfAccounts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TableForSettingUpFormationOfTransactions.Enabled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableData);
	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

&AtClient
Procedure MarkTableElements(Check) 
	
	For Each String In TableForSettingUpFormationOfTransactions Do
		
		If String.Enabled Then
			String.Check = Check;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function AddressInTemporaryStorageOfChartsOfAccounts()
	Return PutToTempStorage(TableForSettingUpFormationOfTransactions.Unload(), UUID)
EndFunction

&AtServer
Procedure SetVisibilityAvailability()
	
	Filter = New Structure;
	Filter.Insert("Enabled", False);
	FoundRows = TableForSettingUpFormationOfTransactions.FindRows(Filter);
	NumberOfRowsFound = FoundRows.Count();
	
	If NumberOfRowsFound Then
		
		Items.TableForSettingUpFormationOfTransactions.ToolTip = NStr("vi = 'Để có thể sử dụng các phần tử, cần bật sử dụng kết xuất đối với hệ thống tài khoản tương ứng';
																		|ru = 'Для доступности элементов необходимо включить выгрузку у соответсвующих планов счетов';
																		|en = 'To make the items available, enable the export for the corresponding charts of accounts'; fa = 'برای در دسترس قرار دادن اقلام، خروج اطلاعات را برای سرفصل حساب‌های مربوطه فعال کنید';
																		|it = 'Per accedere agli elementi è necessario attivare l''upload presso i piani dei conti corrispondenti';
																		|pl = 'Dla dostępności elementów należy włączyć eksport odpowiednich planów kont';
																		|tr = 'Öğelerin kullanılabilir olması için ilgili hesap planlarının yüklenmesini etkinleştirmeniz gerekir.'");
		Items.TableForSettingUpFormationOfTransactions.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
		
	Else
		
		Items.TableForSettingUpFormationOfTransactions.ToolTip = "";
		Items.TableForSettingUpFormationOfTransactions.ToolTipRepresentation = ToolTipRepresentation.None;
		
	EndIf;
	
EndProcedure

#EndRegion
