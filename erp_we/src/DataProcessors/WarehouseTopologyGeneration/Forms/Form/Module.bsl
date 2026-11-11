
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FillInDefaultValues();
	
	ParametersToBeSpecified = New Structure("Warehouse, Premise");
	FillPropertyValues(ParametersToBeSpecified, Object);
	
	SetFormFunctionalOptionParameters(ParametersToBeSpecified);
	
	Object.StorageBinType = Enums.TypesOfStorageCells.Location;
	
	TimeArray_ = New Array;
	TimeArray_.Add("Sections_");
	TimeArray_.Add("Rules");
	TimeArray_.Add("Racks");
	TimeArray_.Add("Tiers");
	TimeArray_.Add("Positions");
	
	AddressParts = New FixedArray(TimeArray_);
	
	TimeArray_ = New Array;
	TimeArray_.Add("GroupRangeOfNumbers");
	TimeArray_.Add("RangeOfNumbersFrom");
	TimeArray_.Add("RangeOfNumbersUpTo");
	TimeArray_.Add("LeadingZeros");
	TimeArray_.Add("DigitCount");
	
	NumericNames = New FixedArray(TimeArray_);
	
	TimeArray_ = New Array;
	TimeArray_.Add("CreateGroups");
	TimeArray_.Add("Separator");
	TimeArray_.Add("NumberType");
	TimeArray_.Add("Count");
	
	CommonNames = New FixedArray(TimeArray_);
	
	TimeArray_ = New Array;
	TimeArray_.Add("GroupRangeOfLetters");
	TimeArray_.Add("RangeOfLettersFrom");
	TimeArray_.Add("RangeOfLettersUpTo");
	
	SymbolicNames = New FixedArray(TimeArray_);
	
	SeparatorLine = " .-_";
	
	WarehouseSpaceWhenServerChanges();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Object.AvailabilityLevel		= 1;
	Object.UpdateExistingItems	= False;
	
	Object.MaximumFillingRateByWeight	= 100;
	Object.MaximumFillingRateByVolume	= 100;
	
	For Each AddressLevel In AddressParts Do
		Object[NameOfDetailsForPartOfAddress("SetOfLetters", AddressLevel)]	= NStr("vi = 'VN';
																						|ru = 'РУС';
																						|en = 'ENG'; fa = 'ENG';
																						|it = 'RUS';
																						|pl = 'ENG';
																						|tr = 'Rusça'");
		Object[NameOfDetailsForPartOfAddress("NumberType", AddressLevel)]	= NStr("vi = 'Theo số';
																					|ru = 'Числовой';
																					|en = 'Numeric'; fa = 'عددی';
																					|it = 'Numerico';
																					|pl = 'Numeric';
																					|tr = 'Sayısal'");
		Object[NameOfDetailsForPartOfAddress("Count", AddressLevel)]	= 1;
		
		If AddressLevel <> "Positions" Then
			Object[NameOfDetailsForPartOfAddress("Separator", AddressLevel)] = "-";
		EndIf;
		
		Object[NameOfDetailsForPartOfAddress("RangeOfNumbersFrom", AddressLevel)]	= 1;
		Object[NameOfDetailsForPartOfAddress("RangeOfNumbersUpTo", AddressLevel)]	= 1;
		Object[NameOfDetailsForPartOfAddress("DigitCount", AddressLevel)]	= 1;
	EndDo;
	
	For Each AddressLevel In AddressParts Do
		SetVisibilityByUsage(AddressLevel);
		SetAvailabilityByLeadingZeros(AddressLevel);
	EndDo;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseSpaceWhenServerChanges();
	
EndProcedure

&AtClient
Procedure PremiseOnChange(Item)
	
	WarehouseSpaceWhenServerChanges();
	
EndProcedure

&AtClient
Procedure UseOnChange(Item)
	
	LevelName = Item.Name;
	
	If Item.Name <> "Positions" Then
		Object[NameOfDetailsForPartOfAddress("CreateGroups", LevelName)] = Object[LevelName];
	EndIf;
	
	If Not Object[LevelName] Then
		Object[NameOfDetailsForPartOfAddress("Count", LevelName)] = 1;
	Else
		CalculateNumberOfLevelElements(LevelName);
	EndIf;
	
	SetVisibilityByUsage(LevelName);
	BuildExample();
	CalculateNumberOfElements();
	
EndProcedure

&AtClient
Procedure TheDelimiterWhenChanging(Item)
	
	BuildExample();
	
EndProcedure

&AtClient
Procedure NumberTypeWhenChanging(Item)
	
	LevelName = LevelNameByPropsName(Items, Item.Name);
	
	If StrFind(Upper(Object[NameOfDetailsForPartOfAddress("NumberType", LevelName)]), "ENG") <> 0 Then
		Object[NameOfDetailsForPartOfAddress("SetOfLetters", LevelName)] = "ENG";
	ElsIf StrFind(Upper(Object[NameOfDetailsForPartOfAddress("NumberType", LevelName)]), "LAT") <> 0 Then
		Object[NameOfDetailsForPartOfAddress("SetOfLetters", LevelName)] = "LAT";
	EndIf;
	
	BuildTemplateByNumberFrom(LevelName);
	CheckNumberToByNumberFrom(LevelName);
	
	SetVisibilityByUsage(LevelName);
	
	BuildExample();
	CalculateNumberOfLevelElements(LevelName);
	CalculateNumberOfElements();
	
EndProcedure

&AtClient
Procedure TheRangeOfLettersFromWhenChanging(Item)
	
	LevelName = LevelNameByPropsName(Items, Item.Name);
	
	BuildTemplateByNumberFrom(LevelName);
	CheckNumberToByNumberFrom(LevelName);
	
	BuildExample();
	CalculateNumberOfLevelElements(LevelName);
	CalculateNumberOfElements();
	
EndProcedure

&AtClient
Procedure RangeOfLettersUpToWhenChanging(Item)
	
	LevelName = LevelNameByPropsName(Items, Item.Name);
	
	CheckNumberToByNumberFrom(LevelName);
	
	BuildExample();
	CalculateNumberOfLevelElements(LevelName);
	CalculateNumberOfElements();
	
EndProcedure

&AtClient
Procedure RangeOfNumbersFromWhenChanging(Item)
	
	LevelName = LevelNameByPropsName(Items, Item.Name);
	
	NameRangeOfNumbersFrom = NameOfDetailsForPartOfAddress("RangeOfNumbersFrom", LevelName);
	NameRangeOfNumbersUpTo = NameOfDetailsForPartOfAddress("RangeOfNumbersUpTo", LevelName);
	
	If Object[NameRangeOfNumbersFrom] > Object[NameRangeOfNumbersUpTo] Then
		Object[NameRangeOfNumbersUpTo] = Object[NameRangeOfNumbersFrom];
	EndIf;
	
	CheckNumberOfDigits(LevelName);
	
	BuildExample();
	CalculateNumberOfLevelElements(LevelName);
	CalculateNumberOfElements();
	
EndProcedure

&AtClient
Procedure RangeOfNumbersUpToWhenChanging(Item)
	
	LevelName = LevelNameByPropsName(Items, Item.Name);
	
	NameRangeOfNumbersFrom = NameOfDetailsForPartOfAddress("RangeOfNumbersFrom", LevelName);
	NameRangeOfNumbersUpTo = NameOfDetailsForPartOfAddress("RangeOfNumbersUpTo", LevelName);
	
	If Object[NameRangeOfNumbersFrom] > Object[NameRangeOfNumbersUpTo] Then
		Object[NameRangeOfNumbersUpTo] = Object[NameRangeOfNumbersFrom];
	EndIf;
	
	CheckNumberOfDigits(LevelName);
	
	CalculateNumberOfLevelElements(LevelName);
	CalculateNumberOfElements();
	
EndProcedure

&AtClient
Procedure LeadingZerosWhenChanging(Item)
	
	LevelName = LevelNameByPropsName(Items, Item.Name);
	
	CheckNumberOfDigits(LevelName);
	
	SetAvailabilityByLeadingZeros(LevelName);
	BuildExample();
	
EndProcedure

&AtClient
Procedure NumberOfDigitsWhenChanging(Item)
	
	LevelName = LevelNameByPropsName(Items, Item.Name);
	
	CheckNumberOfDigits(LevelName);
	BuildExample();
	
EndProcedure

&AtClient
Procedure LetterRangeFromRegulation(Item, Direction, StandardProcessing)
	
	StandardProcessing = False;
	
	CurNumber	= Object[Item.Name];
	LevelName	= LevelNameByPropsName(Items, Item.Name);
	
	If CurNumber <> "" Then
		If Direction > 0 Then
			Number = NextLevelNumber(CurNumber, LevelName, False);
		Else
			Number = PreviousLevelNumber(CurNumber, LevelName, False);
		EndIf;
		
		If Number <> CurNumber Then
			Object[Item.Name] = Number;
			
			BuildTemplateByNumberFrom(LevelName);
			CheckNumberToByNumberFrom(LevelName);
			
			BuildExample();
			CalculateNumberOfLevelElements(LevelName);
			CalculateNumberOfElements();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure RangeOfSectionLettersUntilTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = False;
	
	CurNumber	= Object[Item.Name];
	LevelName	= LevelNameByPropsName(Items, Item.Name);
	
	If CurNumber <> "" Then
		If Direction > 0 Then
			Number = NextLevelNumber(CurNumber, LevelName, False);
		Else
			Number = PreviousLevelNumber(CurNumber, LevelName, False);
		EndIf;
		
		If Number <> CurNumber Then
			Object[Item.Name] = Number;
			
			CheckNumberToByNumberFrom(LevelName);
			CalculateNumberOfLevelElements(LevelName);
			CalculateNumberOfElements();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Preview(Command)
	
	ClearMessages();
	
	WarehouseStructure_ = GenerateWarehouseStructure(True);
	
	If WarehouseStructure_ <> Undefined Then
		WarehouseStructure_.Show(NStr("vi = 'Xem trước cấu trúc kho';
										|ru = 'Предварительный просмотр структуры склада';
										|en = 'Warehouse structure preview'; fa = 'Warehouse structure preview';
										|it = 'Anteprima della struttura del magazzino';
										|pl = 'Podgląd struktury magazynu';
										|tr = 'Ambar yapısı önizlemesi'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateStructure(Command)
	
	ClearMessages();
	
	CallbackDescription = New CallbackDescription("CreateStructureCompletion", ThisObject);
	
	If Object.UpdateExistingItems Then
		QueryText = NStr("vi = 'Tạo (cập nhật) các phần tử của danh mục ""Ô hàng""?';
						|ru = 'Создать (обновить) элементы справочника ""Складские ячейки""?';
						|en = 'Create (update) items of catalog ""Storage bins""?'; fa = 'Create (update) items of catalog ""Storage bins""?';
						|it = 'Creare (aggiornare) elementi della directory ""Celle del magazzino""?';
						|pl = 'Utwórz (zaktualizuj) elementy katalogu ""Komórki magazynu""?';
						|tr = '""Depo yerleri"" kataloğunun öğelerini oluştur (güncelle)?'");
	Else
		QueryText = NStr("vi = 'Tạo các phần tử danh mục ""Ô hàng""?';
						|ru = 'Создать элементы справочника ""Складские ячейки""?';
						|en = 'Create items of the ""Storage bins"" catalog?'; fa = 'Create items of the ""Storage bins"" catalog?';
						|it = 'Creare elementi della directory ""Celle del magazzino""?';
						|pl = 'Utwórz elementy katalogu ""Komórki magazynu""?';
						|tr = '""Depo yerleri"" kataloğunun öğelerini oluştur?'");
	EndIf;
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No);
	
EndProcedure

&AtClient
Procedure CreateStructureCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	MessageText = NStr("vi = 'Đang xử lý danh mục ""Ô hàng""...';
						|ru = 'Идет обработка справочника ""Складские ячейки""...';
						|en = 'Processing catalog ""Storage bins""...'; fa = 'Processing catalog ""Storage bins""...';
						|it = 'Elaborazione della directory ""Celle del magazzino"" è in corso...';
						|pl = 'Przetwarzanie katalogu ""Komórki magazynu""...';
						|tr = '""Depo yerleri"" kataloğu işleniyor ...'");
	
	Status(MessageText);
	GenerateWarehouseStructure(False);
	
	MessageText = NStr("vi = 'Việc xử lý danh mục ""Ô hàng"" đã hoàn thành.';
						|ru = 'Обработка справочника ""Складские ячейки"" завершена.';
						|en = 'Catalog ""Storage bins"" has been processed.'; fa = 'Catalog ""Storage bins"" has been processed.';
						|it = 'Elaborazione della directory ""Celle del magazzino"" è stata completata.';
						|pl = 'Przetwarzanie katalogu ""Komórki magazynu"" zostało zakończone.';
						|tr = '""Depo yerleri"" kataloğunun işlemesi tamamlandı.'");
	
	Status(MessageText);
	
EndProcedure

&AtClient
Procedure UpdateTheDetailsWhenChanging(Item)
	
	If Item = Items.UpdateStandardSize Then
		FormItem = Items.StandardSize;
	ElsIf Item = Items.UpdateMaximumFillingRateByWeight Then
		FormItem = Items.MaximumFillingRateByWeight;
	ElsIf Item = Items.UpdateWarehouseZone Then
		FormItem = Items.WarehouseZone;
	ElsIf Item = Items.UpdateMaximumFillingRateByVolume Then
		FormItem = Items.MaximumFillingRateByVolume;
	ElsIf Item = Items.UpdateStorageArea Then
		FormItem = Items.StorageArea;
	ElsIf Item = Items.UpdateAvailabilityLevel Then
		FormItem = Items.AvailabilityLevel;
	EndIf;
	
	FormItem.Enabled = Object[Item.Name];
	
EndProcedure

#EndRegion

#Region Private

#Region FillingAndInitialization

&AtServer
Procedure FillInDefaultValues()
	
	Object.Warehouse = SettingsValueCached.GetDefaultWarehouse(Object.Warehouse);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function NewCatalogGroup(CurrentParent, Address)
	
	CatalogRef = Catalogs.StorageBins.FindByCode(Address, , , Object.Warehouse);
	
	If CatalogRef.IsEmpty() Then
		CatalogObject = Catalogs.StorageBins.CreateFolder();
	ElsIf Object.UpdateExistingItems Then
		CatalogObject = CatalogRef.GetObject();
	Else
		Return CatalogRef;
	EndIf;
	
	CatalogObject.Code			= Address;
	CatalogObject.Description	= Address;
	CatalogObject.Owner		= Object.Warehouse;
	CatalogObject.Premise		= Object.Premise;
	CatalogObject.Parent		= CurrentParent;
	
	Try
		If CatalogObject.CheckFilling() Then
			CatalogObject.Write();
			
			CatalogRef = CatalogObject.Ref;
		EndIf;
	Except
		CatalogRef = Catalogs.StorageBins.EmptyRef();
		
		MessageText = NStr("vi = 'Nhóm ""%Group%"" chưa ghi lại: %ErrorInfo%';
							|ru = 'Группа ""%Group%"" не записана: %ErrorInfo%';
							|en = 'Group ""%Group%"" is not saved: %ErrorInfo%'; fa = 'Group ""%Group%"" is not saved: %ErrorInfo%';
							|it = 'Il gruppo ""%Group%"" non è registrato: %ErrorInfo%';
							|pl = 'Grupa ""%Group%"" nie jest zapisana: %ErrorInfo%';
							|tr = '""%Group%"" grup kaydedilmedi: %ErrorInfo%'");
		MessageText = StrReplace(MessageText, "%Group%", Address);
		MessageText = StrReplace(MessageText, "%ErrorInfo%", ErrorInfo().Description);
		
		Common.MessageToUser(MessageText);
	EndTry;
	
	Return CatalogRef;
	
EndFunction

&AtServer
Procedure CreateCatalogItem(CurrentParent, Address, Section3, Line, Rack, Tier, Position)
	
	CatalogRef = Catalogs.StorageBins.FindByCode(Address, , , Object.Warehouse);
	
	If CatalogRef.IsEmpty() Then
		CatalogObject = Catalogs.StorageBins.CreateItem();
	ElsIf Object.UpdateExistingItems Then
		CatalogObject = CatalogRef.GetObject();
		
		If CatalogObject.IsFolder Then
			ErrorInformationText = NStr("vi = 'Không thể tạo ô hàng với địa chỉ %Cell%, vì đã có nhóm ô hàng có địa chỉ như vậy.';
										|ru = 'Не возможно создать ячейку с адресом %Cell%, т.к. уже существует группа ячеек с таким адресом.';
										|en = 'Cannot create a bin with location %Cell% as a bin group with this location already exists.'; fa = 'Cannot create a bin with location %Cell% as a bin group with this location already exists.';
										|it = 'Non è possibile creare una cella con l''indirizzo %Cell%, perché esiste già un gruppo di celle con questo indirizzo.';
										|pl = 'Nie można utworzyć komórki z adresem %Cell%, ponieważ Istnieje już grupa komórek o tym adresie.';
										|tr = 'Adresli bir hücre oluşturmak mümkün değildir %Cell%, çünkü bu adrese sahip bir hücre grubu mevcut.'");
			ErrorInformationText = StrReplace(ErrorInformationText, "%Cell%", CatalogObject.Code);
			
			Common.MessageToUser(ErrorInformationText);
			
			Return;
		EndIf;
	Else
		MessageText = NStr("vi = 'Ô hàng ""%Item%"" đã có trong cấu trúc kho bãi';
							|ru = 'Ячейка ""%Item%"" уже есть в структуре склада';
							|en = 'Storage bin ""%Item%"" is already in the warehouse structure'; fa = 'Storage bin ""%Item%"" is already in the warehouse structure';
							|it = 'La cella ""%Item%"" già presente nella struttura del magazzino';
							|pl = 'Komórka ""%Item%"" już znajduje się w strukturze magazynu';
							|tr = '""%Item%"" hücresi ambar yapısında artık mevcut'");
		MessageText = StrReplace(MessageText, "%Item%", Address);
		MessageText = StrReplace(MessageText, "%ErrorInfo%", ErrorInfo().Description);
		
		Common.MessageToUser(MessageText);
		
		Return;
	EndIf;
	
	CatalogObject.Code				= Address;
	CatalogObject.Description		= Address;
	CatalogObject.Owner			= Object.Warehouse;
	CatalogObject.Premise			= Object.Premise;
	CatalogObject.Parent			= CurrentParent;
	CatalogObject.StorageBinType	= Object.StorageBinType;
	
	CatalogObject.Section3		= Section3;
	CatalogObject.Line		= Line;
	CatalogObject.Rack	= Rack;
	CatalogObject.Tier		= Tier;
	CatalogObject.Position	= Position;
	
	If Object.UpdateWarehouseZone Then
		CatalogObject.WarehouseZone = Object.WarehouseZone;
	EndIf;
	
	If Object.UpdateStorageArea Then
		CatalogObject.StorageArea = Object.StorageArea;
	EndIf;
	
	If Object.UpdateAvailabilityLevel Then
		CatalogObject.AvailabilityLevel = Object.AvailabilityLevel;
	EndIf;
	
	If Object.UpdateStandardSize Then
		CatalogObject.StandardSize = Object.StandardSize;
	EndIf;
	
	If Object.UpdateMaximumFillingRateByWeight Then
		CatalogObject.MaximumFillingRateByWeight = Object.MaximumFillingRateByWeight;
	EndIf;
	
	If Object.UpdateMaximumFillingRateByVolume Then
		CatalogObject.MaximumFillingRateByVolume = Object.MaximumFillingRateByVolume;
	EndIf;
	
	CatalogObject.UseFrequencyOfBinInventoryRecounts = Enums.OptionsOfUsingPeriodicPhysicalInventoryCountOfBins.UseStorageAreaSettings;
	
	Try
		If CatalogObject.CheckFilling() Then
			CatalogObject.Write();
			
			CatalogRef = CatalogObject.Ref;
		EndIf;
	Except
		CatalogRef = Catalogs.StorageBins.EmptyRef();
		
		MessageText = NStr("vi = 'Phần tử ""%Item%"" chưa ghi lại: %ErrorInfo%';
							|ru = 'Элемент ""%Item%"" не записан: %ErrorInfo%';
							|en = 'Item ""%Item%"" is not saved:%ErrorInfo%'; fa = 'Item ""%Item%"" is not saved:%ErrorInfo%';
							|it = 'Elemento ""%Item%"" non è registrato: %ErrorInfo%';
							|pl = 'Element ""%Item%"" nie jest nagrana: %ErrorInfo%';
							|tr = '""%Item%"" öğesi kaydedilmedi: %ErrorInfo%'");
		MessageText = StrReplace(MessageText,"%Item%",Address);
		
		If Not Common.ObjectAttributeValue(CurrentParent, "IsFolder") Then
			ErrorInformationText = NStr("vi = 'Không thể tạo nhóm ô hàng với địa chỉ %CurrentParent%, vì đã có ô hàng có địa chỉ như vậy.';
										|ru = 'Не возможно создать группу ячеек с адресом %CurrentParent%, т.к. уже существует ячейка с таким адресом.';
										|en = 'Cannot create a bin group with location %CurrentParent% as a bin with this location already exists.'; fa = 'Cannot create a bin group with location %CurrentParent% as a bin with this location already exists.';
										|it = 'Non è possibile creare un gruppo di celle con l''indirizzo %CurrentParent%, perché esiste già una cella con questo indirizzo.';
										|pl = 'Nie można utworzyć grupy komórek z adresem %CurrentParent%, ponieważ Istnieje już komórka z tym adresem.';
										|tr = 'Adresli bir hücre grubu oluşturmak mümkün değildir %CurrentParent%, bu adrese sahip bir hücre artık mevcut.'");
			ErrorInformationText = StrReplace(ErrorInformationText, "%CurrentParent%", CurrentParent);
		Else
			ErrorInformationText = ErrorInfo().Description;
		EndIf;
		MessageText = StrReplace(MessageText, "%ErrorInfo%", ErrorInformationText);
		
		Common.MessageToUser(MessageText);
	EndTry;
	
EndProcedure

&AtServer
Procedure GenerateLevelArray(LevelName, LevelArray, Counter)
	
	If Object[LevelName] Then
		CurNumber	= "";
		OldNumber	= "old_";
		
		While True Do
			CurNumber = NextLevelNumber(CurNumber,LevelName);
			
			If OldNumber <> CurNumber Then
				LevelArray.Add(CurNumber);
				
				OldNumber = CurNumber;
				
				Counter = Counter + 1;
			Else
				Break;
			EndIf;
		EndDo;
	Else
		LevelArray.Add("");
	EndIf;
	
EndProcedure

&AtServer
Function NextLevelNumber(CurNumber, LevelName, ConsiderRanges = True)
	
	NewNumber = "";
	
	Code0 = 48;
	Code9 = 57;
	
	If Object[NameOfDetailsForPartOfAddress("NumberType", LevelName)] = "Numeric" Then
		
		If ConsiderRanges Then
			NumberFrom_ = Object[NameOfDetailsForPartOfAddress("RangeOfNumbersFrom", LevelName)];
			NumberUpTo = Object[NameOfDetailsForPartOfAddress("RangeOfNumbersUpTo", LevelName)];
		Else
			NumberFrom_ = 0;
			NumberUpTo = Pow(10,NumberOfLevelDigits(LevelName)) - 1;
		EndIf;
		
		LidirZeros	= Object[NameOfDetailsForPartOfAddress("LeadingZeros", LevelName)];
		NumberLength	= Object[NameOfDetailsForPartOfAddress("DigitCount", LevelName)];
		
		If IsBlankString(CurNumber) Then
			NewNumber = Format(NumberFrom_, "ND=" + String(NumberLength) + "; NZ=; " + ?(LidirZeros, "NLZ=;", "")+ "NG=0");
		Else
			CurNumber_ = Number(CurNumber)+ 1;
			If CurNumber_ <= NumberUpTo Then 
				NewNumber = Format(CurNumber_, "ND=" + String(NumberLength) + "; NZ=; " + ?(LidirZeros, "NLZ=;", "") + "NG=0");
			Else
				NewNumber = CurNumber;
			EndIf;
		EndIf;
		
	Else
		
		Template = Object[NameOfDetailsForPartOfAddress("Template", LevelName)];
		NumberLength = StrLen(Template);
		
		NumberFrom = Object[NameOfDetailsForPartOfAddress("RangeOfLettersFrom", LevelName)];
		NumberTo = Object[NameOfDetailsForPartOfAddress("RangeOfLettersUpTo", LevelName)];
		
		If IsBlankString(CurNumber) Then //Generating the first number
			NewNumber = NumberFrom;
		Else //Generating the next number
			
			ItIsNecessaryToIncrease	= True;
			CurDischarge		= NumberLength;
			NewNumber		= CurNumber;
			SetOfLetters		= Object[NameOfDetailsForPartOfAddress("SetOfLetters", LevelName)];
			
			While CurDischarge > 0
				And ItIsNecessaryToIncrease Do
				
				If ConsiderRanges Then
					SymbolFrom = CharCode(Mid(NumberFrom, CurDischarge, 1));
					SymbolBefore = CharCode(Mid(NumberTo, CurDischarge, 1));
				Else
					If CharCode(Mid(NumberFrom, CurDischarge, 1)) > CharCode("9") Then
						SymbolFrom = MinimumLevelLetter(SetOfLetters);
						SymbolBefore = MaximumLevelLetter(SetOfLetters);
					Else
						SymbolFrom = CharCode("1");
						SymbolBefore = CharCode("9");
					EndIf;
				EndIf;
				
				CurCharacterCode = CharCode(Mid(NewNumber, CurDischarge, 1));
				
				If CurDischarge > 1 Then
					NextCharacterCode = CharCode(Mid(NewNumber, CurDischarge - 1, 1));
					CharacterIsFollowingBefore = CharCode(Mid(NumberTo, CurDischarge - 1, 1));
				Else
					NextCharacterCode = -1;
					CharacterIsFollowingBefore = -1;
				EndIf;
				
				If NextCharacterCode < 0 
					Or Not IsDigit(NextCharacterCode)
					Or Not IsDigit(CurCharacterCode) Then
					
					If CurCharacterCode < SymbolBefore Then
						// If possible, increase the current discharge
						NewNumber = Left(NewNumber, CurDischarge - 1) + Char(CurCharacterCode + 1)
										+ Right(NewNumber, NumberLength - CurDischarge);
						ItIsNecessaryToIncrease = False;
					Else
						// otherwise, we reset the current discharge and move on to a higher discharge
						NewNumber = Left(NewNumber, CurDischarge - 1) + Char(SymbolFrom)
										+ Right(NewNumber, NumberLength - CurDischarge);
					EndIf;
					
				Else
					If NextCharacterCode < CharacterIsFollowingBefore Then
						
						If CurCharacterCode < Code9 Then
							// If possible, increase the current discharge
							NewNumber = Left(NewNumber, CurDischarge - 1) + Char(CurCharacterCode + 1)
											+ Right(NewNumber, NumberLength - CurDischarge);
							ItIsNecessaryToIncrease = False;
						Else
							// otherwise, we reset the current discharge and move on to a higher discharge
							NewNumber = Left(NewNumber, CurDischarge - 1) + Char(Code0)
											+ Right(NewNumber, NumberLength - CurDischarge);
						EndIf;
						
					Else
						If CurCharacterCode < SymbolBefore Then
							// If possible, increase the current discharge
							NewNumber = Left(NewNumber, CurDischarge - 1) + Char(CurCharacterCode + 1)
											+ Right(NewNumber, NumberLength - CurDischarge);
							ItIsNecessaryToIncrease = False;
						Else
							// otherwise, we reset the current discharge and move on to a higher discharge
							NewNumber = Left(NewNumber, CurDischarge - 1) + Char(SymbolFrom)
											+ Right(NewNumber, NumberLength - CurDischarge);
						EndIf;
					EndIf;
				EndIf;
				
				CurDischarge = CurDischarge - 1;
				
			EndDo;
			
			If ItIsNecessaryToIncrease Then
				NewNumber = CurNumber;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return NewNumber;
	
EndFunction

&AtServer
Function PreviousLevelNumber(CurNumber, LevelName, ConsiderRanges = True)
	
	NewNumber = "";
	
	Code0 = 48;
	Code9 = 57;
	
	If Object[NameOfDetailsForPartOfAddress("NumberType", LevelName)] = "Numeric" Then
		
		NumberFrom_		= ?(ConsiderRanges, Object[NameOfDetailsForPartOfAddress("RangeOfNumbersFrom", LevelName)], 0);
		LidirZeros	= Object[NameOfDetailsForPartOfAddress("LeadingZeros", LevelName)];
		NumberLength	= Object[NameOfDetailsForPartOfAddress("DigitCount", LevelName)];
		
		If IsBlankString(CurNumber) Then
			NewNumber = Format(NumberFrom_, "ND=" + String(NumberLength) + "; NZ=; " + ?(LidirZeros, "NLZ=;", "") + "NG=0");
		Else
			CurNumber_ = Number(CurNumber)- 1;
			If CurNumber_ >= NumberFrom_ Then 
				NewNumber = Format(CurNumber_,"ND="+String(NumberLength)+"; NZ=; " + ?(LidirZeros, "NLZ=;", "")+ "NG=0");
			Else
				NewNumber = CurNumber;
			EndIf;
		EndIf;
		
	Else
		
		Template = Object[NameOfDetailsForPartOfAddress("Template", LevelName)];
		NumberLength = StrLen(Template); 
		
		NumberFrom = Object[NameOfDetailsForPartOfAddress("RangeOfLettersFrom", LevelName)];
		NumberTo = Object[NameOfDetailsForPartOfAddress("RangeOfLettersUpTo", LevelName)];
		
		If IsBlankString(CurNumber) Then //Generating the first number
			NewNumber = NumberFrom;
		Else //Generating the previous number
			
			ItIsNecessaryToReduce	= True;
			CurDischarge		= NumberLength;
			NewNumber		= CurNumber;
			SetOfLetters		= Object[NameOfDetailsForPartOfAddress("SetOfLetters", LevelName)];

			While CurDischarge > 0
				And ItIsNecessaryToReduce Do
				
				If ConsiderRanges Then
					SymbolFrom = CharCode(Mid(NumberFrom, CurDischarge, 1));
					SymbolBefore = CharCode(Mid(NumberTo, CurDischarge, 1));
				Else
					If CharCode(Mid(NumberFrom, CurDischarge, 1)) > CharCode("9") Then
						SymbolFrom = MinimumLevelLetter(SetOfLetters);
						SymbolBefore = MaximumLevelLetter(SetOfLetters);
					Else
						SymbolFrom = CharCode("1");
						SymbolBefore = CharCode("9");
					EndIf;
				EndIf;
				
				CurCharacterCode = CharCode(Mid(NewNumber, CurDischarge, 1));
				
				If CurDischarge > 1 Then
					NextCharacterCode = CharCode(Mid(NewNumber, CurDischarge - 1, 1));
					
					If ConsiderRanges Then
						SymbolFollowingFrom = CharCode(Mid(NumberFrom, CurDischarge-1, 1));
					Else
						SymbolFollowingFrom = MinimumLevelLetter(LevelName);
					EndIf;
				Else
					NextCharacterCode = -1;
					SymbolFollowingFrom = -1;
				EndIf;
				
				If NextCharacterCode < 0 
					Or Not IsDigit(NextCharacterCode)
					Or Not IsDigit(CurCharacterCode) Then
					
					If  CurCharacterCode > SymbolFrom Then
						// If possible, reduce the current discharge
						NewNumber = Left(NewNumber, CurDischarge - 1) + Char(CurCharacterCode - 1)
										+ Right(NewNumber, NumberLength - CurDischarge);
						ItIsNecessaryToReduce = False;
					Else
						// otherwise, we reset the current discharge and move on to a higher discharge
						NewNumber = Left(NewNumber, CurDischarge - 1) + Char(SymbolBefore)
										+ Right(NewNumber, NumberLength - CurDischarge);
					EndIf;
					
				Else
					If NextCharacterCode > SymbolFollowingFrom Then
						
						If CurCharacterCode > Code0 Then
							// If possible, increase the current discharge
							NewNumber = Left(NewNumber, CurDischarge - 1) + Char(CurCharacterCode - 1)
											+ Right(NewNumber, NumberLength - CurDischarge);
							ItIsNecessaryToReduce = False;
						Else
							// otherwise, we reset the current discharge and move on to a higher discharge
							NewNumber = Left(NewNumber, CurDischarge - 1) + Char(Code9)
											+Right(NewNumber, NumberLength - CurDischarge);
						EndIf;
						
					Else
						If CurCharacterCode > SymbolFrom Then
							// If possible, reduce the current discharge
							NewNumber = Left(NewNumber, CurDischarge - 1) + Char(CurCharacterCode - 1)
											+ Right(NewNumber, NumberLength - CurDischarge);
							ItIsNecessaryToReduce = False;
						Else
							// otherwise, we reset the current discharge and move on to a higher discharge
							NewNumber = Left(NewNumber, CurDischarge - 1) + CharCode(SymbolFrom)
											+ Right(NewNumber, NumberLength - CurDischarge);
						EndIf;
					EndIf;
				
				EndIf;
				
				CurDischarge = CurDischarge - 1;
				
			EndDo;
			
			If ItIsNecessaryToReduce Then
				NewNumber = CurNumber;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return NewNumber;
	
EndFunction

&AtServer
Procedure BuildExample()
	
	ExampleRow = "";
	
	For Each AddressLevel In AddressParts Do
		If Object[AddressLevel] Then
			NewNumber = NextLevelNumber("", AddressLevel);
			ExampleRow = ExampleRow + TrimAll(NewNumber) + LevelSeparator(AddressLevel);
		EndIf;
	EndDo;
	
	RemoveSeparatorAtEnd(ExampleRow, SeparatorLine);
	
	Object.Sample = ExampleRow;
	
EndProcedure

&AtServer
Function LevelSeparator(LevelName)
	
	Separator = "";
	
	If LevelName <> "Positions" Then
		Separator = TrimAll(Object[NameOfDetailsForPartOfAddress("Separator", LevelName)]);
		
		If Not IsBlankString(Separator) Then
			If Separator = "P" Then
				Separator = " ";
			ElsIf Separator = "N" Then
				Separator = "";
			EndIf;
		EndIf;
	EndIf;
	
	Return Separator;
	
EndFunction

&AtServer
Function AddressByNumbers(Section3, Line, Rack = Undefined, Tier = Undefined, Position = Undefined)
	
	Address = "";
	
	If ValueIsFilled(Section3) Then
		Address = Address + TrimAll(Section3) + LevelSeparator("Sections_");
	EndIf;
	
	If ValueIsFilled(Line) Then
		Address = Address + TrimAll(Line) + LevelSeparator("Rules");
	EndIf;
	
	If ValueIsFilled(Rack) Then
		Address = Address + TrimAll(Rack) + LevelSeparator("Racks");
	EndIf;
	
	If ValueIsFilled(Tier) Then
		Address = Address + TrimAll(Tier) + LevelSeparator("Tiers");
	EndIf;
	
	If ValueIsFilled(Position) Then
		Address = Address + TrimAll(Position);
	EndIf;
	
	RemoveSeparatorAtEnd(Address, SeparatorLine);
	
	Return Address;
	
EndFunction

&AtServer
Function GenerateWarehouseStructure(ToTabularDocument = True)
	
	Cancel = False;
	
	If Not NumbersAreFilledInCorrectly() Then
		Cancel = True;
	EndIf;
	
	If Not ToTabularDocument
		And Not CheckFilling() Then
		
		Cancel = True;
		
	EndIf;
	
	If Cancel Then
		Return Undefined;
	EndIf;
	
	If ToTabularDocument Then
		TabDoc = New SpreadsheetDocument;
		TabDoc.ShowGrid = False;
		
		Template = DataProcessors.WarehouseTopologyGeneration.GetTemplate("Template");
		
		HeaderArea_	= Template.GetArea("Title");
		GroupArea		= Template.GetArea("GroupArea");
		TableCellArea		= Template.GetArea("TableCellArea");
		
		TabDoc.Put(HeaderArea_);
		TabDoc.StartRowAutoGrouping();
	EndIf;
	
	Sections_		= New Array;
	Rules		= New Array;
	Racks	= New Array;
	Tiers		= New Array;
	Positions		= New Array;
	
	Counter = 0;
	
	GenerateLevelArray("Sections_", Sections_, Counter);
	GenerateLevelArray("Rules", Rules, Counter);
	GenerateLevelArray("Racks", Racks, Counter);
	GenerateLevelArray("Tiers", Tiers, Counter);
	GenerateLevelArray("Positions", Positions, Counter);
	
	LastLevelName = "";
	
	If Object.Sections_ Then
		LastLevelName = "Sections_";
	EndIf;
	If Object.Rules Then
		LastLevelName = "Rules";
	EndIf;
	If Object.Racks Then
		LastLevelName = "Racks";
	EndIf;
	If Object.Tiers Then
		LastLevelName = "Tiers";
	EndIf;
	If Object.Positions Then
		LastLevelName = "Positions";
	EndIf;
	
	If LastLevelName <> "Positions" Then
		Object[NameOfDetailsForPartOfAddress("CreateGroups", LastLevelName)] = False;
	EndIf;
	
	Level = 0;
	
	ParentOfSections		= Catalogs.StorageBins.EmptyRef();
	ParentOfLines		= Catalogs.StorageBins.EmptyRef();
	ShelvingParent	= Catalogs.StorageBins.EmptyRef();
	ParentOfTiers		= Catalogs.StorageBins.EmptyRef();
	ParentOfPositions		= Catalogs.StorageBins.EmptyRef();
	
	For Each Section3 In Sections_ Do
		
		If Object["Sections_"]
			And Object["CreateGroupsSections"] Then
			
			Address = AddressByNumbers(Section3, Undefined);
			
			If ToTabularDocument Then
				GroupArea.Parameters.Group = Address;
				
				TabDoc.Put(GroupArea, Level);
			Else
				ParentOfLines = NewCatalogGroup(ParentOfSections, Address);
			EndIf;
			
			Level = Level + 1;
			
		Else
			ParentOfLines = ParentOfSections;
		EndIf;
		
		For Each Line In Rules Do
			
			If Object["Rules"]
				And Object["CreateGroupsLines"] Then
				
				Address = AddressByNumbers(Section3, Line);
				
				If ToTabularDocument Then
					GroupArea.Parameters.Group = Address;
					
					TabDoc.Put(GroupArea, Level);
				Else
					ShelvingParent = NewCatalogGroup(ParentOfLines, Address);
				EndIf;
				
				Level = Level + 1;
				
			Else
				ShelvingParent = ParentOfLines;
			EndIf;
			
			For Each Rack In Racks Do
				
				If Object["Racks"]
					And Object["CreateGroupsRacks"] Then
					
					Address = AddressByNumbers(Section3, Line, Rack);
					
					If ToTabularDocument Then
						GroupArea.Parameters.Group = Address;
						
						TabDoc.Put(GroupArea, Level);
					Else
						ParentOfTiers = NewCatalogGroup(ShelvingParent, Address);
					EndIf;
					
					Level = Level + 1;
					
				Else
					ParentOfTiers = ShelvingParent;
				EndIf;
				
				For Each Tier In Tiers Do
					
					If Object["Tiers"]
						And Object["CreateGroupsTiers"] Then
						
						Address = AddressByNumbers(Section3, Line, Rack, Tier);
						
						If ToTabularDocument Then
							GroupArea.Parameters.Group = Address;
							
							TabDoc.Put(GroupArea, Level);
						Else
							ParentOfPositions = NewCatalogGroup(ParentOfTiers, Address);
						EndIf;
						
						Level = Level + 1;
						
					Else
						ParentOfPositions = ParentOfTiers;
					EndIf;
					
					Level = Level + 1;
					
					For Each Position In Positions Do
						
						Address = AddressByNumbers(Section3, Line, Rack, Tier, Position);
						
						If ToTabularDocument Then
							TableCellArea.Parameters.Cell = Address;
							
							TabDoc.Put(TableCellArea,Level);
						Else
							CreateCatalogItem(ParentOfPositions,
														Address,
														Section3,
														Line,
														Rack,
														Tier,
														Position);
						EndIf;
						
					EndDo;
					
					Level = Level - 1;
					
					If Object["Tiers"]
						And Object["CreateGroupsTiers"] Then
						
						Level = Level - 1;
						
					EndIf;
					
				EndDo;
				
				If Object["Racks"]
					And Object["CreateGroupsRacks"] Then
					
					Level = Level - 1;
					
				EndIf;
				
			EndDo;
			
			If Object["Rules"]
				And Object["CreateGroupsLines"] Then
			
				Level = Level - 1;
				
			EndIf;
			
		EndDo;
		
		If Object["Sections_"]
			And Object["CreateGroupsSections"] Then
			
			Level = Level - 1;
			
		EndIf;
		
	EndDo;

	If ToTabularDocument Then
		TabDoc.EndRowAutoGrouping();
		
		Return TabDoc;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtServer
Function NumbersAreFilledInCorrectly()
	
	Result = True;
	ThereAreLevels = False;
	
	MessageTemplate = NStr("vi = 'Chưa điền trường ""%FieldName%"" ở lớp đánh địa chỉ ""%LevelName%""';
							|ru = 'Не заполнено поле ""%FieldName%"" в уровне адресации ""%LevelName%""';
							|en = '""%FieldName%"" is required in addressing level ""%LevelName%""'; fa = '""%FieldName%"" is required in addressing level ""%LevelName%""';
							|it = 'Il campo ""%FieldName%"" nel livello di indirizzamento ""%LevelName%"" non è compilato';
							|pl = 'Niewypełnione pole ""%FieldName%"" w poziomie adresowania ""%LevelName%""';
							|tr = 'Adresleme  ""%FieldName%"" düzeyinde alan doldurulmadı ""%LevelName%""'");
	
	For Each LevelName In AddressParts Do
		If Object[LevelName] Then
			ThereAreLevels = True;
			
			LevelElement = Items[LevelName]; // FormField
			LevelNameLocalized = LevelElement.Title;
			
			If Object[NameOfDetailsForPartOfAddress("NumberType", LevelName)] <> "Numeric" Then
				
				If Not ValueIsFilled(Object[NameOfDetailsForPartOfAddress("RangeOfLettersFrom", LevelName)]) Then
					Result = False;
									
					MessageText = StrReplace(MessageTemplate,"%FieldName%", NStr("vi = 'Số từ';
																				|ru = 'Номер от';
																				|en = 'Number from'; fa = 'Number from';
																				|it = 'Numero da';
																				|pl = 'Numer od';
																				|tr = 'Sayı'"));
					MessageText = StrReplace(MessageText,"%LevelName%", LevelNameLocalized);
					
					Common.MessageToUser(MessageText,,NameOfDetailsForPartOfAddress("RangeOfLettersFrom", LevelName), "Object"); 
				EndIf;
				
				If Not ValueIsFilled(Object[NameOfDetailsForPartOfAddress("RangeOfLettersUpTo", LevelName)]) Then
					Result = False;
									
					MessageText = StrReplace(MessageTemplate,"%FieldName%", NStr("vi = 'Số đến';
																				|ru = 'Номер до';
																				|en = 'Number to'; fa = 'Number to';
																				|it = 'Numero fino a';
																				|pl = 'Numer do';
																				|tr = 'Sayı'"));
					MessageText = StrReplace(MessageText,"%LevelName%", LevelNameLocalized);
					
					Common.MessageToUser(MessageText,,NameOfDetailsForPartOfAddress("RangeOfLettersUpTo", LevelName), "Object"); 
				EndIf;
				
			Else
				
				If Not ValueIsFilled(Object[NameOfDetailsForPartOfAddress("RangeOfNumbersFrom", LevelName)]) Then
					Result = False;
									
					MessageText = StrReplace(MessageTemplate,"%FieldName%", NStr("vi = 'Số từ';
																				|ru = 'Номер от';
																				|en = 'Number from'; fa = 'Number from';
																				|it = 'Numero da';
																				|pl = 'Numer od';
																				|tr = 'Sayı'"));
					MessageText = StrReplace(MessageText,"%LevelName%", LevelNameLocalized);
					
					Common.MessageToUser(MessageText,,NameOfDetailsForPartOfAddress("RangeOfNumbersFrom", LevelName), "Object"); 
				EndIf;
				
				If Not ValueIsFilled(Object[NameOfDetailsForPartOfAddress("RangeOfNumbersUpTo", LevelName)]) Then
					Result = False;
									
					MessageText = StrReplace(MessageTemplate,"%FieldName%", NStr("vi = 'Số đến';
																				|ru = 'Номер до';
																				|en = 'Number to'; fa = 'Number to';
																				|it = 'Numero fino a';
																				|pl = 'Numer do';
																				|tr = 'Sayı'"));
					MessageText = StrReplace(MessageText,"%LevelName%", LevelNameLocalized);
					
					Common.MessageToUser(MessageText,,NameOfDetailsForPartOfAddress("RangeOfNumbersUpTo", LevelName), "Object"); 
				EndIf;
				
			EndIf;
			
		EndIf;
	EndDo;
	
	If Not ThereAreLevels Then
		MessageText = NStr("vi = 'Chưa chọn bất kỳ một lớp đánh địa chỉ nào';
							|ru = 'Не выбран ни один уровень адресации.';
							|en = 'No bin location level is selected.'; fa = 'No bin location level is selected.';
							|it = 'Non è stato selezionato alcun livello di indirizzamento.';
							|pl = 'Nie wybrano poziomu adresu.';
							|tr = 'Hiç bir adresleme düzeyi seçilmedi.'");
		Common.MessageToUser(MessageText); 
		Result = False;	
	EndIf;
		
	Return Result;
	
EndFunction

&AtServer
Procedure WarehouseSpaceWhenServerChanges()
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse, Premise", Object.Warehouse, Object.Premise));
	
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, ,False);
	
	Items.MaximumFullnessRatioByWeightPercentage.Visible	= UseBinLocationWarehousing;
	Items.MaximumFillingRatioByVolumePercentage.Visible	= UseBinLocationWarehousing;
	
EndProcedure

&AtServer
Function IsDigit(CharCode)
	
	Code0 = 48;
	Code9 = 57;
	
	If CharCode >= Code0
		And CharCode <= Code9 Then
		
		Return True;
		
	Else
		Return False;
	EndIf;
	
EndFunction

&AtClientAtServerNoContext 
Function MaximumLevelLetter(SetOfLetters)
	
	If SetOfLetters = "ENG" Then
		EndCharacterCode = 1071;
	Else
		EndCharacterCode = 90;
	EndIf;
	
	Return EndCharacterCode;
	
EndFunction

&AtClientAtServerNoContext 
Function MinimumLevelLetter(SetOfLetters)
	
	If SetOfLetters = "ENG" Then
		InitialCharacterCode = 1040;
	Else
		InitialCharacterCode = 65;
	EndIf;
	
	Return InitialCharacterCode;
	
EndFunction

&AtClientAtServerNoContext
Procedure RemoveSeparatorAtEnd(Address, SeparatorLine)
	
	Address = TrimAll(Address);
	AddressLength = StrLen(Address);
	
	If AddressLength > 0 Then
		LastChar = Right(Address, 1);
		
		If StrFind(SeparatorLine, LastChar) <> 0 Then
			Address = Left(Address,AddressLength - 1);
		EndIf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function NumberOfLevelDigits(LevelName)
	
	If LevelName = "Positions" Then
		LengthMax = 2;
	ElsIf LevelName = "Racks" Then
		LengthMax = 5;
	Else
		LengthMax = 3;
	EndIf;
	
	Return LengthMax;
	
EndFunction

&AtClient
Procedure SetVisibilityByUsage(LevelName)
	
	For Each CommonName In CommonNames Do
		If Not ((CommonName = "CreateGroups"
				Or CommonName = "Separator")
			And LevelName = "Positions") Then
			
			Items[NameOfDetailsForPartOfAddress(CommonName, LevelName)].Visible = Object[LevelName];
			
		EndIf;
	EndDo;
	
	If Object[NameOfDetailsForPartOfAddress("NumberType", LevelName)] = "Numeric" Then
		For Each NumberName In NumericNames Do
			If NumberName = "LeadingZeros" Then
				Items[NameOfDetailsForPartOfAddress(NumberName, LevelName)].Enabled = True;
			ElsIf NumberName = "DigitCount" Then	
				Items[NameOfDetailsForPartOfAddress(NumberName, LevelName)].Enabled = Object[PropsNameLeadingZeros(LevelName)];
			EndIf;
			
			Items[NameOfDetailsForPartOfAddress(NumberName, LevelName)].Visible = Object[LevelName];
		EndDo;
		
		For Each SymbolName In SymbolicNames Do
			Items[NameOfDetailsForPartOfAddress(SymbolName, LevelName)].Visible = False;
		EndDo;
	Else
		For Each SymbolName In SymbolicNames Do
			Items[NameOfDetailsForPartOfAddress(SymbolName, LevelName)].Visible = Object[LevelName];
		EndDo;
		
		For Each NumberName In NumericNames Do
			If NumberName = "LeadingZeros"
				Or NumberName = "DigitCount" Then
				
				Items[NameOfDetailsForPartOfAddress(NumberName, LevelName)].Enabled = False;
				Items[NameOfDetailsForPartOfAddress(NumberName, LevelName)].Visible = Object[LevelName];
				
			Else
				Items[NameOfDetailsForPartOfAddress(NumberName, LevelName)].Visible = False;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Function PropsNameLeadingZeros(LevelName)
	
	If LevelName = "Sections_" Then
		Return "LeadingZerosSections";
	ElsIf LevelName = "Rules" Then
		Return "LeadingZerosLines";
	ElsIf LevelName = "Racks" Then
		Return "LeadingZerosRacks";
	ElsIf LevelName = "Tiers" Then
		Return "LeadingZerosTiers";
	ElsIf LevelName = "Positions" Then
		Return "ItemLeadingZeros";
	EndIf;
	
EndFunction

&AtClient
Procedure SetAvailabilityByLeadingZeros(LevelName)
	
	LevelElement = Items[NameOfDetailsForPartOfAddress("DigitCount", LevelName)]; // FormField
	LevelElement.Enabled = Object[NameOfDetailsForPartOfAddress("LeadingZeros", LevelName)];

EndProcedure

&AtClient
Procedure CalculateNumberOfLevelElements(LevelName)
	
	NameQuantity = NameOfDetailsForPartOfAddress("Count", LevelName);
	
	Object[NameQuantity] = 1;
	
	If Object[NameOfDetailsForPartOfAddress("NumberType", LevelName)] = "Numeric" Then
		Object[NameQuantity] = Object[NameOfDetailsForPartOfAddress("RangeOfNumbersUpTo", LevelName)]
								- Object[NameOfDetailsForPartOfAddress("RangeOfNumbersFrom", LevelName)] + 1;
	Else
		Template = Object[NameOfDetailsForPartOfAddress("Template", LevelName)];
		NumberLength = StrLen(Template); 
		
		For CurDischarge = 1 To NumberLength Do
			LetterFrom = CharCode(Mid(Object[NameOfDetailsForPartOfAddress("RangeOfLettersFrom", LevelName)], CurDischarge, 1));
			LetterBefore = CharCode(Mid(Object[NameOfDetailsForPartOfAddress("RangeOfLettersUpTo", LevelName)] ,CurDischarge, 1));
			
			NumberOfLetters = LetterBefore - LetterFrom + 1;
			
			Object[NameQuantity] = Object[NameQuantity] * NumberOfLetters;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculateNumberOfElements()
	
	If Not (Object.Sections_
		Or Object.Rules
		Or Object.Racks
		Or Object.Tiers
		Or Object.Positions) Then
		
		Object.NumberOfBins = 0;
		
	Else
		
		Object.NumberOfBins = Object.NumberSections * Object.LineQuantity * Object.NumberRacks
									* Object.QuantityTiers * Object.ItemQuantity;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BuildTemplateByNumberFrom(LevelName)
	
	NumberFrom		= Object[NameOfDetailsForPartOfAddress("RangeOfLettersFrom", LevelName)];
	SetOfLetters	= Object[NameOfDetailsForPartOfAddress("SetOfLetters", LevelName)];
	
	NumberFrom = TrimAll(Upper(NumberFrom));
	
	InitialCharacterCode	= MinimumLevelLetter(SetOfLetters);
	EndCharacterCode		= MaximumLevelLetter(SetOfLetters);
	
	Code0 = 48;
	Code9 = 57;
	
	NumberFrom = TrimAll(NumberFrom);
	NumberLength = StrLen(NumberFrom);
	
	NewTemplate = "";
	
	For CurDischarge = 1 To NumberLength Do
		
		SymbolFrom = CharCode(Mid(NumberFrom,CurDischarge,1));
		
		If SymbolFrom >= InitialCharacterCode
			And SymbolFrom <= EndCharacterCode Then
			
			NewTemplate = NewTemplate + Char(SymbolFrom);
			
		ElsIf SymbolFrom >= Code0
			And SymbolFrom <= Code9 Then
			
			NewTemplate = NewTemplate + Char(SymbolFrom);
			
		Else
			NewTemplate = NewTemplate + Char(InitialCharacterCode);
			NumberFrom = Left(NumberFrom, CurDischarge - 1) + Char(InitialCharacterCode) + Right(NumberFrom, NumberLength - CurDischarge);
		EndIf;
		
	EndDo;
	
	Object[NameOfDetailsForPartOfAddress("RangeOfLettersFrom", LevelName)] = NumberFrom;
	Object[NameOfDetailsForPartOfAddress("Template", LevelName)] = NewTemplate;
	
EndProcedure

&AtClient
Procedure CheckNumberToByNumberFrom(LevelName)
	
	Template		= Object[NameOfDetailsForPartOfAddress("Template", LevelName)];
	SetOfLetters	= Object[NameOfDetailsForPartOfAddress("SetOfLetters", LevelName)];
	NumberFrom		= Object[NameOfDetailsForPartOfAddress("RangeOfLettersFrom", LevelName)];
	NumberTo		= Object[NameOfDetailsForPartOfAddress("RangeOfLettersUpTo", LevelName)];
	
	NumberLength		= StrLen(Template);
	NumberLengthUpTo	= StrLen(NumberTo);
	
	If NumberLengthUpTo < NumberLength  Then
		For IndexOf = 1 To NumberLengthUpTo - NumberLength Do
			NumberTo = NumberTo + " ";
		EndDo;
	ElsIf NumberLengthUpTo > NumberLength Then
		NumberTo = Left(NumberFrom, NumberLength);
	EndIf;
	
	NumberTo = Upper(NumberTo);
	
	InitialCharacterCode	= MinimumLevelLetter(SetOfLetters);
	EndCharacterCode		= MaximumLevelLetter(SetOfLetters);
	
	For CurDischarge = 1 To NumberLength Do
		
		SymbolFrom = CharCode(Mid(NumberFrom, CurDischarge, 1));
		CurCharacterCode = CharCode(Mid(NumberTo, CurDischarge, 1));
		
		If CurCharacterCode < SymbolFrom Then
			NumberTo = Left(NumberTo, CurDischarge - 1) + Char(SymbolFrom) + Right(NumberTo, NumberLength - CurDischarge);
		Else
			CodeCurPatternSymbol = CharCode(Mid(Template, CurDischarge, 1));
			
			If CodeCurPatternSymbol >= InitialCharacterCode 
				And CodeCurPatternSymbol <= EndCharacterCode Then
				
				If CurCharacterCode > EndCharacterCode Then
					NumberTo = Left(NumberTo, CurDischarge - 1) + Char(SymbolFrom) + Right(NumberTo, NumberLength - CurDischarge);
				EndIf;
				
			Else
				If CurCharacterCode > 57 Then
					NumberTo = Left(NumberTo, CurDischarge - 1) + Char(SymbolFrom) + Right(NumberTo, NumberLength - CurDischarge);
				EndIf;
			EndIf;
		EndIf;
			
	EndDo;
	
	Object[NameOfDetailsForPartOfAddress("RangeOfLettersUpTo", LevelName)] = NumberTo;
	
EndProcedure

&AtClient
Procedure CheckNumberOfDigits(LevelName)
	
	NameNumberOfDigits = NameOfDetailsForPartOfAddress("DigitCount", LevelName);
	
	NumberLength	= StrLen(Format(Object[NameOfDetailsForPartOfAddress("RangeOfNumbersUpTo", LevelName)], "NZ=; NG=0"));
	LengthMax	= NumberOfLevelDigits(LevelName);
	
	If Object[NameNumberOfDigits] < NumberLength Then
		Object[NameNumberOfDigits] = NumberLength;
	ElsIf Not Object[NameOfDetailsForPartOfAddress("LeadingZeros", LevelName)] Then
		Object[NameNumberOfDigits] = NumberLength;
	ElsIf Object[NameNumberOfDigits] > LengthMax Then
		Object[NameNumberOfDigits] = LengthMax;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function NameOfDetailsForPartOfAddress(ParameterName, PartOfAddress)
	
	If ParameterName = "CreateGroups" Then
		
		If PartOfAddress = "Sections_" Then
			
			Return "CreateGroupsSections";
			
		ElsIf PartOfAddress = "Rules" Then
			
			Return "CreateGroupsLines";
			
		ElsIf PartOfAddress = "Racks" Then
			
			Return "CreateGroupsRacks";
			
		ElsIf PartOfAddress = "Tiers" Then
			
			Return "CreateGroupsTiers";
			
		ElsIf PartOfAddress = "Positions" Then
			
			Return "CreatePositionGroups";
			
		EndIf;
		
	ElsIf ParameterName = "GroupRangeOfNumbers" Then
		
		If PartOfAddress = "Sections_" Then
			
			Return "GroupRangeOfSectionNumbers";
			
		ElsIf PartOfAddress = "Rules" Then
			
			Return "GroupRangeOfLineNumbers";
			
		ElsIf PartOfAddress = "Racks" Then
			
			Return "GroupRangeOfNumbersRacks";
			
		ElsIf PartOfAddress = "Tiers" Then
			
			Return "GroupRangeOfNumbersTiers";
			
		ElsIf PartOfAddress = "Positions" Then
			
			Return "GroupRangeOfPositionNumbers";
			
		EndIf;
		
	ElsIf ParameterName = "GroupRangeOfLetters" Then
		
		If PartOfAddress = "Sections_" Then
			
			Return "TheGroupIsTheRangeOfLettersSection";
			
		ElsIf PartOfAddress = "Rules" Then
			
			Return "TheGroupIsTheRangeOfLettersOfTheLine";
			
		ElsIf PartOfAddress = "Racks" Then
			
			Return "GroupRangeOfLettersRacks";
			
		ElsIf PartOfAddress = "Tiers" Then
			
			Return "TheGroupIsTheRangeOfLettersTheTiers";
			
		ElsIf PartOfAddress = "Positions" Then
			
			Return "TheGroupIsTheRangeOfLettersPositions";
			
		EndIf;
		
	ElsIf ParameterName = "Template" Then
		
		If PartOfAddress = "Sections_" Then
			
			Return "SectionTemplate";
			
		ElsIf PartOfAddress = "Rules" Then
			
			Return "LineTemplate";
			
		ElsIf PartOfAddress = "Racks" Then
			
			Return "TemplateRacks";
			
		ElsIf PartOfAddress = "Tiers" Then
			
			Return "TemplateTiers";
			
		ElsIf PartOfAddress = "Positions" Then
			
			Return "ItemTemplate";
			
		EndIf;
		
	ElsIf ParameterName = "Separator" Then
		
		If PartOfAddress = "Sections_" Then
			
			Return "SeparatorSections";
			
		ElsIf PartOfAddress = "Rules" Then
			
			Return "SeparatorLines";
			
		ElsIf PartOfAddress = "Racks" Then
			
			Return "SeparatorRacks";
			
		ElsIf PartOfAddress = "Tiers" Then
			
			Return "SeparatorTiers";
			
		ElsIf PartOfAddress = "Positions" Then
			
			Return "PositionSeparator";
			
		EndIf;
		
	ElsIf ParameterName = "RangeOfLettersFrom" Then
		
		If PartOfAddress = "Sections_" Then
			
			Return "RangeOfSectionLettersFrom";
			
		ElsIf PartOfAddress = "Rules" Then
			
			Return "RangeOfLettersFromLine";
			
		ElsIf PartOfAddress = "Racks" Then
			
			Return "RangeOfRackLettersFrom";
			
		ElsIf PartOfAddress = "Tiers" Then
			
			Return "RangeOfTierLettersFrom";
			
		ElsIf PartOfAddress = "Positions" Then
			
			Return "RangeOfItemLettersFrom";
			
		EndIf;
		
	ElsIf ParameterName = "RangeOfLettersUpTo" Then
		
		If PartOfAddress = "Sections_" Then
			
			Return "RangeOfSectionLettersUntil";
			
		ElsIf PartOfAddress = "Rules" Then
			
			Return "RangeOfLettersUpToLine";
			
		ElsIf PartOfAddress = "Racks" Then
			
			Return "RangeOfRackLettersUntil";
			
		ElsIf PartOfAddress = "Tiers" Then
			
			Return "RangeOfTierLettersUntil";
			
		ElsIf PartOfAddress = "Positions" Then
			
			Return "RangeOfItemLettersUntil";
			
		EndIf;
		
	ElsIf ParameterName = "DigitCount" Then
		
		If PartOfAddress = "Sections_" Then
			
			Return "NumberOfSectionDigits";
			
		ElsIf PartOfAddress = "Rules" Then
			
			Return "RangeOfSectionDigitsUntil";
			
		ElsIf PartOfAddress = "Racks" Then
			
			Return "RangeOfLineDigitsFrom";
			
		ElsIf PartOfAddress = "Tiers" Then
			
			Return "NumberOfDigitsTiers";
			
		ElsIf PartOfAddress = "Positions" Then
			
			Return "RangeOfRackDigitsFrom";
			
		EndIf;
		
	ElsIf ParameterName = "Count" Then
		
		If PartOfAddress = "Sections_" Then
			
			Return "NumberSections";
			
		ElsIf PartOfAddress = "Rules" Then
			
			Return "LineQuantity";
			
		ElsIf PartOfAddress = "Racks" Then
			
			Return "NumberRacks";
			
		ElsIf PartOfAddress = "Tiers" Then
			
			Return "QuantityTiers";
				
		ElsIf PartOfAddress = "Positions" Then
			
			Return "ItemQuantity";
			
		EndIf;
		
	ElsIf ParameterName = "RangeOfNumbersFrom" Then
		
		If PartOfAddress = "Sections_" Then
			
			Return "RangeOfSectionNumbersFrom";
			
		ElsIf PartOfAddress = "Rules" Then
			
			Return "RangeOfNumbersFromLine";
			
		ElsIf PartOfAddress = "Racks" Then
			
			Return "RangeOfRackNumbersFrom";
			
		ElsIf PartOfAddress = "Tiers" Then
			
			Return "RangeOfTierNumbersFrom";
			
		ElsIf PartOfAddress = "Positions" Then
			
			Return "RangeOfItemNumbersFrom";
			
		EndIf;
		
	ElsIf ParameterName = "RangeOfNumbersUpTo" Then
		
		If PartOfAddress = "Sections_" Then
			
			Return "RangeOfSectionNumbersUntil";
			
		ElsIf PartOfAddress = "Rules" Then
			
			Return "RangeOfNumbersUpToLine";
			
		ElsIf PartOfAddress = "Racks" Then
			
			Return "RangeOfRackNumbersUntil";
			
		ElsIf PartOfAddress = "Tiers" Then
			
			Return "RangeOfTierNumbersUntil";
			
		ElsIf PartOfAddress = "Positions" Then
			
			Return "RangeOfItemNumbersUntil";
			
		EndIf;
		
	ElsIf ParameterName = "LeadingZeros" Then
		
		If PartOfAddress = "Sections_" Then
			
			Return "LeadingZerosSections";
			
		ElsIf PartOfAddress = "Rules" Then
			
			Return "LeadingZerosLines";
			
		ElsIf PartOfAddress = "Racks" Then
			
			Return "LeadingZerosRacks";
			
		ElsIf PartOfAddress = "Tiers" Then
			
			Return "LeadingZerosTiers";
			
		ElsIf PartOfAddress = "Positions" Then
			
			Return "ItemLeadingZeros";
			
		EndIf;
		
	ElsIf ParameterName = "NumberType" Then
		
		If PartOfAddress = "Sections_" Then
			
			Return "NumberTypeSections";
			
		ElsIf PartOfAddress = "Rules" Then
			
			Return "NumberTypeLines";
			
		ElsIf PartOfAddress = "Racks" Then
			
			Return "NumberTypeRacks";
			
		ElsIf PartOfAddress = "Tiers" Then
			
			Return "NumberTypeTiers";
			
		ElsIf PartOfAddress = "Positions" Then
			
			Return "NumberTypePositions";
			
		EndIf;
		
	ElsIf ParameterName = "SetOfLetters" Then
		
		If PartOfAddress = "Sections_" Then
			
			Return "LetterSetSections";
			
		ElsIf PartOfAddress = "Rules" Then
			
			Return "LetterSetLines";
			
		ElsIf PartOfAddress = "Racks" Then
			
			Return "LetterSetRacks";
			
		ElsIf PartOfAddress = "Tiers" Then
			
			Return "LetterSetTiers";
			
		ElsIf PartOfAddress = "Positions" Then
			
			Return "LetterSetOfItems";
			
		EndIf;
		
	EndIf;
	
	ExceptionText = StrTemplate(NStr("vi = 'Không có mục tin đối với tham số ""%1"" và một phần địa chỉ ""%2"".';
									|ru = 'Отсутствует реквизит для параметра ""%1"" и части адреса ""%2"".';
									|en = 'No attribute for parameter ""%1"" and address part ""%2"".'; fa = 'No attribute for parameter ""%1"" and address part ""%2"".';
									|it = 'Requisito mancante per il parametro ""%1"" e parte dell''indirizzo ""%2"".';
									|pl = 'Brak atrybutu dla parametru ""%1"" i części adresu ""%2"".';
									|tr = '""%1"" parametresi ve ""%2"" adres bölümü için öznitelik mevcut değildir.'"),
								ParameterName,
								PartOfAddress);
	
	Raise ExceptionText;
	
EndFunction

&AtClientAtServerNoContext
Function LevelNameByPropsName(Items, TagName)
	
	LevelName = "";
	
	SectionLevelElements = New Array;
	SectionLevelElements.Add(Items.NumberTypeSections.Name);
	SectionLevelElements.Add(Items.RangeOfSectionLettersFrom.Name);
	SectionLevelElements.Add(Items.RangeOfSectionLettersUntil.Name);
	SectionLevelElements.Add(Items.RangeOfSectionNumbersFrom.Name);
	SectionLevelElements.Add(Items.RangeOfSectionNumbersUntil.Name);
	SectionLevelElements.Add(Items.LeadingZerosSections.Name);
	SectionLevelElements.Add(Items.NumberOfSectionDigits.Name);
	
	LineLevelElements = New Array;
	LineLevelElements.Add(Items.NumberTypeLines.Name);
	LineLevelElements.Add(Items.RangeOfLettersFromLine.Name);
	LineLevelElements.Add(Items.RangeOfLettersUpToLine.Name);
	LineLevelElements.Add(Items.RangeOfNumbersFromLine.Name);
	LineLevelElements.Add(Items.RangeOfNumbersUpToLine.Name);
	LineLevelElements.Add(Items.LeadingZerosLines.Name);
	LineLevelElements.Add(Items.RangeOfSectionDigitsUntil.Name);
	
	ShelvingLevelElements = New Array;
	ShelvingLevelElements.Add(Items.NumberTypeRacks.Name);
	ShelvingLevelElements.Add(Items.RangeOfRackLettersFrom.Name);
	ShelvingLevelElements.Add(Items.RangeOfRackLettersUntil.Name);
	ShelvingLevelElements.Add(Items.RangeOfRackNumbersFrom.Name);
	ShelvingLevelElements.Add(Items.RangeOfRackNumbersUntil.Name);
	ShelvingLevelElements.Add(Items.LeadingZerosRacks.Name);
	ShelvingLevelElements.Add(Items.RangeOfLineDigitsFrom.Name);
	
	TierLevelElements = New Array;
	TierLevelElements.Add(Items.NumberTypeTiers.Name);
	TierLevelElements.Add(Items.RangeOfTierLettersFrom.Name);
	TierLevelElements.Add(Items.RangeOfTierLettersUntil.Name);
	TierLevelElements.Add(Items.RangeOfTierNumbersFrom.Name);
	TierLevelElements.Add(Items.RangeOfTierNumbersUntil.Name);
	TierLevelElements.Add(Items.LeadingZerosTiers.Name);
	TierLevelElements.Add(Items.NumberOfDigitsTiers.Name);
	
	PositionLevelElements = New Array;
	PositionLevelElements.Add(Items.NumberTypePositions.Name);
	PositionLevelElements.Add(Items.RangeOfItemLettersFrom.Name);
	PositionLevelElements.Add(Items.RangeOfItemLettersUntil.Name);
	PositionLevelElements.Add(Items.RangeOfItemNumbersFrom.Name);
	PositionLevelElements.Add(Items.RangeOfItemNumbersUntil.Name);
	PositionLevelElements.Add(Items.ItemLeadingZeros.Name);
	PositionLevelElements.Add(Items.RangeOfRackDigitsFrom.Name);
	
	If SectionLevelElements.Find(TagName) <> Undefined Then
		LevelName = "Sections_";
	ElsIf LineLevelElements.Find(TagName) <> Undefined Then
		LevelName = "Rules";
	ElsIf ShelvingLevelElements.Find(TagName) <> Undefined Then
		LevelName = "Racks";
	ElsIf TierLevelElements.Find(TagName) <> Undefined Then
		LevelName = "Tiers";
	ElsIf PositionLevelElements.Find(TagName) <> Undefined Then
		LevelName = "Positions";
	EndIf;
	
	If ValueIsFilled(LevelName) Then
		Return LevelName;
	Else
		ExceptionText = StrTemplate(NStr("vi = 'Không thể xác định lớp địa chỉ đối với mục tin ""%1"".';
										|ru = 'Не удалось определить уровень адреса для реквизита ""%1"".';
										|en = 'Cannot determine the address layer of the ""%1"" attribute.'; fa = 'Cannot determine the address layer of the ""%1"" attribute.';
										|it = 'Impossibile definire il livello dell''indirizzo per il requisito ""%1"".';
										|pl = 'Nie udało się określić poziomu adresu dla atrybutu ""%1"".';
										|tr = '""%1"" özniteliği için adres düzeyi belirlenemedi.'"),
									TagName);
		
		Raise ExceptionText;
	EndIf;
	
EndFunction

#EndRegion

#EndRegion
