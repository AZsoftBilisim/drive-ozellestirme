#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

	Catalogs.PackagesAndUnitsOfMeasure.WorkOutLogicOfConnectionDetails(ThisObject);
	
	If MeasuredValueType <> Enums.TypesOfMeasuredValues.Package Then
		Return;
	EndIf;
	
	If IsNew() Then
		AdditionalProperties.Insert("NeedToUpdateRepackagingOptions", True);
		AdditionalProperties.Insert("IsNew", True);
		AdditionalProperties.Insert("CoefficientHasChanged", False);
		AdditionalProperties.Insert("ChangedParent", False);
		AdditionalProperties.Insert("FormerParent", Undefined);
	Else
		
		AdditionalProperties.Insert("IsNew", False);
		
		DetailsBeforeRecording = Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(Ref,
			Undefined,
			"Parent, Numerator, Denominator, NumberOfPackages, DeletionMark");
		
		CoefficientHasChanged = DetailsBeforeRecording.Numerator <> Numerator
							Or DetailsBeforeRecording.Denominator <> Denominator
							Or DetailsBeforeRecording.NumberOfPackages <> NumberOfPackages;
		
		If DetailsBeforeRecording.Parent <> Parent
			Or CoefficientHasChanged
			Or DeletionMark <> DetailsBeforeRecording.DeletionMark Then
			
			AdditionalProperties.Insert("CoefficientHasChanged", CoefficientHasChanged);
			AdditionalProperties.Insert("ChangedParent", DetailsBeforeRecording.Parent <> Parent);
			AdditionalProperties.Insert("NeedToUpdateRepackagingOptions", True);
			
			If AdditionalProperties.ChangedParent Then
				AdditionalProperties.Insert("FormerParent", DetailsBeforeRecording.Parent);
			Else
				AdditionalProperties.Insert("FormerParent", Undefined);
			EndIf;
			
		Else
			AdditionalProperties.Insert("NeedToUpdateRepackagingOptions", False);
			AdditionalProperties.Insert("CoefficientHasChanged", False);
			AdditionalProperties.Insert("ChangedParent", False);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Correction of the register of information "Repackaging options"
	If ValueIsFilled(Parent) Then
		
		Block = New DataLock;
		
		Item = Block.Add("Catalog.PackagesAndUnitsOfMeasure");
		Item.SetValue("Ref", Parent);
		Item.Mode = DataLockMode.Shared;
		
		Block.Lock();
		
		Query = New Query;
		Query.SetParameter("Parent", Parent);
		Query.Text =
		"SELECT
		|	TRUE AS ParentExists
		|FROM
		|	Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
		|WHERE
		|	PackagesAndUnitsOfMeasure.Ref = &Parent";
		
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty()
			And Not ThereAreRepackagingOptions(Parent) Then
			
			RecordSet = InformationRegisters.RepackagingOptions.CreateRecordSet();
			RecordSet.Filter.Package.Set(Ref);
			RecordSet.Read();
			
			If RecordSet.Count() <> 0 Then
				
				OldMaximumPacking = RecordSet[0].MaximumPackageInABranch;
				
				// Replace the old Maximum packaging with a new one
				RecordSet = InformationRegisters.RepackagingOptions.CreateRecordSet();
				RecordSet.Filter.MaximumPackageInABranch.Set(OldMaximumPacking);
				RecordSet.Read();
				
				RegisterTable = RecordSet.Unload();
				
				RecordSet = InformationRegisters.RepackagingOptions.CreateRecordSet();
				RecordSet.Filter.MaximumPackageInABranch.Set(Parent);
				RecordSet.Read();
				
				RegisterTable.FillValues(Parent, "MaximumPackageInABranch");
				
				RecordSet.Load(RegisterTable);
				RecordSet.Write();
				
				// Add an entry with an empty source
				RecordSet.Filter.MaximumPackageInABranch.Set(Parent);
				RecordSet.Filter.Source.Set(Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
				RecordSet.Filter.Package.Set(Parent);
				RecordSet.Read();
				
				NewRecord = RecordSet.Add();
				NewRecord.Package = Parent;
				NewRecord.MaximumPackageInABranch = Parent;
				RecordSet.Write();
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If FillingData <> Undefined Then 
		
		If FillingData.Property("MeasuredValueType",MeasuredValueType)
			And MeasuredValueType = Enums.TypesOfMeasuredValues.Package Then
			
			If (Not FillingData.Property("Owner",Owner)
				Or Not ValueIsFilled(Owner)) Then
				
				ExceptionText = NStr("vi = 'Cần tạo đóng gói từ biểu mẫu mặt hàng hoặc từ bộ đóng gói.';
									|ru = 'Упаковку нужно создавать из формы номенклатуры или набора упаковок.';
									|en = 'To create a packaging unit, open an item form or a packaging group.'; fa = 'To create a packaging unit, open an item form or a packaging group.';
									|it = 'L''imballaggio deve essere creato dalla forma di un articolo o di una serie di imballaggi.';
									|pl = 'Opakowanie należy tworzyć z formularza towarów lub zestawu opakowań.';
									|tr = 'Öğe formundan veya paketleme grubundan paketleme ünitesi oluşturulmalıdır.'");
				
				Raise ExceptionText;
				
			EndIf;
			
			If TypeOf(FillingData.Owner) = Type("CatalogRef.Products") Then
				ValueOfBankingDetails = Common.ObjectAttributesValues(FillingData.Owner, "UsePackages,PackagingGroup");
				If Not ValueOfBankingDetails.UsePackages Then
					ExceptionText = NStr("vi = 'Trong thẻ mặt hàng %Products% không có đóng bộ. Không thể tạo đóng bộ.';
										|ru = 'В карточке номенклатуры %Products% не включено использование упаковок. Создание упаковки невозможно.';
										|en = 'Packaging units are disabled for %Products%. Cannot create a packaging unit.'; fa = 'Packaging units are disabled for %Products%. Cannot create a packaging unit.';
										|it = 'La scheda articolo  %Products% non include l''utilizzo di imballaggi. La creazione dell''imballaggio non è possibile.';
										|pl = 'W karcie towaru %Products% nie włączono używania opakowań. Utworzenie opakowania nie jest możliwe.';
										|tr = '%Products% ürün kartı paketleme ünitesi kullanımını içermiyor. Paketleme ünitesi oluşturmak mümkün değildir.'");
					ExceptionText = StrReplace(ExceptionText, "%Products%", String(FillingData.Owner));
					
					Raise ExceptionText;
				EndIf;
				
				If ValueOfBankingDetails.PackagingGroup <> Catalogs.PackagingGroups.SpecialForItem Then
					Owner = ValueOfBankingDetails.PackagingGroup;
				Else
					Owner = FillingData.Owner;
				EndIf;
			EndIf;
			
			If FillingData.Property("Parent", Parent)
				And ValueIsFilled(Parent) Then
				
				ParentPackagingType = Common.ObjectAttributeValue(Parent, "PackageType");
				
				If ParentPackagingType = Enums.TypesOfItemsPackages.CargoItem Then 
					
					StandardProcessing = False;
					PackageType = Enums.TypesOfItemsPackages.CargoItem;
					Parent    = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
					
				Else
					
					PackageType = Enums.TypesOfItemsPackages.Complex;
					
				EndIf;
				
			EndIf;
			
			WarehouseGroup = SettingsValueCached.DefaultWarehouseGroupOfPackages(WarehouseGroup);
			UnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
			
			UnitOfLength = Constants.UnitOfMeasureForLength.Get();
			
			DepthUnitOfMeasure = UnitOfLength;
			WidthUnitOfMeasure  = UnitOfLength;
			HeightUnitOfMeasure  = UnitOfLength;
			
			VolumeUnitOfMeasure   = Constants.UnitOfMeasureForVolume.Get();
			WeightUnitOfMeasure     = Constants.UnitOfMeasureForWeight.Get();
		Else
			Owner = Catalogs.PackagingGroups.BasicUnitsOfMeasure;
		EndIf;
		
	Else
		Owner = Catalogs.PackagingGroups.BasicUnitsOfMeasure;
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If MeasuredValueType <> Enums.TypesOfMeasuredValues.Package Then
		
		NotCheckedAttributeArray.Add("UnitOfMeasure");
		NotCheckedAttributeArray.Add("Parent");
		NotCheckedAttributeArray.Add("NumberOfPackages");
		NotCheckedAttributeArray.Add("ReusablePackageItems");
		NotCheckedAttributeArray.Add("ReusablePackageVariant");
		NotCheckedAttributeArray.Add("PackageType");
		
		If MeasuredValueType = Enums.TypesOfMeasuredValues.NumberOfPieces
			Or Not ValueIsFilled(MeasuredValueType) Then
			
			NotCheckedAttributeArray.Add("Numerator");
			NotCheckedAttributeArray.Add("Denominator");
			
		EndIf;
		
	Else
		
		AttributesStructure1 = New Structure;
		AttributesStructure1.Insert("UnitOfMeasure", "UnitOfMeasure");
		
		If TypeOf(Owner) = Type("CatalogRef.Products") Then
			AttributesStructure1.Insert("PackagingGroup", "PackagingGroup");
			AttributesStructure1.Insert("ItemsType", "ItemsType");
		Else // if the owner is a type of reference set of packages.
			AttributesStructure1.Insert("PackagingGroup", "Ref");
		EndIf;
		
		OwnerDetailsValues = Common.ObjectAttributesValues(Owner, AttributesStructure1);
		
		If TypeOf(Owner) = Type("CatalogRef.Products") Then
			
			If OwnerDetailsValues.PackagingGroup <> Catalogs.PackagingGroups.SpecialForItem Then
				
				MessageText = NStr("vi = 'Đối với mặt hàng %Owner% đã chọn tập hợp đóng gói ""%CurrentValue%"", 
					|vì vậy tất cả đóng gói cần đặt dưới vào tập hợp đóng gói mà không phải vào mặt hàng';
					|ru = 'Для номенклатуры %Owner% выбран набор упаковок ""%CurrentValue%"", 
					|поэтому все упаковки должны подчиняться набору упаковок, а не номенклатуре';
					|en = 'The ""%CurrentValue%"" packaging group is selected for the %Owner% items, 
					|so all packaging units must be subordinate to the packaging group, not the items'; fa = 'The ""%CurrentValue%"" packaging group is selected for the %Owner% items, 
					|so all packaging units must be subordinate to the packaging group, not the items';
					|it = 'Per l''articolo %Owner% è selezionato il kit di imballaggi ""%CurrentValue%"",
					| pertanto, tutti gli imballaggi devono essere conformi all''insieme di imballaggi, non all''articolo';
					|pl = 'Dla towaru %Owner% wybrano zestaw opakowań ""%CurrentValue%"", 
					|dlatego wszystkie opakowania muszą być podporządkowane zestawowi opakowań, a nie towarowi';
					|tr = '%Owner% öğesi için ""%CurrentValue%"" paketleme grubu seçildi, 
					|bu nedenle, tüm paketleme üniteleri öğeye değil, paketleme grubuna uymalıdır'");
				MessageText = StrReplace(MessageText, "%Owner%", String(Owner));
				MessageText = StrReplace(MessageText, "%CurrentValue%", String(OwnerDetailsValues.PackagingGroup));
				
				Common.MessageToUser(MessageText, ThisObject, "Owner", , Cancel);
				
			EndIf;
			
			If OwnerDetailsValues.ItemsType <> Enums.ItemsTypes.OwnGoods Then
				
				MessageText = NStr("vi = 'Mặt hàng %Owner% không phải là một sản phẩm. Bộ đóng gói chỉ dành cho hàng hóa.';
									|ru = 'Номенклатура %Owner% не является товаром. Упаковки ведутся только для товаров.';
									|en = '%Owner% is not inventory. Only inventory can have packaging units.'; fa = '%Owner% is not inventory. Only inventory can have packaging units.';
									|it = 'L''articolo %Owner% non è una merce. L''imballaggio è previsto solamente per la merce.';
									|pl = 'Pozycja %Owner% nie jest towarom. Opakowania są prowadzone tylko dla towarów.';
									|tr = '%Owner% öğesi ürün değildir. Paketleme sadece ürünler için yapılmakta. '");
				MessageText = StrReplace(MessageText, "%Owner%", String(Owner));
				
				Common.MessageToUser(MessageText, ThisObject, "Owner",, Cancel);
				
			EndIf;
			
		Else // if the owner is a type of reference set of packages.
			
			If OwnerDetailsValues.PackagingGroup = Catalogs.PackagingGroups.SpecialForItem Then
				
				MessageText = NStr("vi = 'Đối với mặt hàng %Owner% đã chọn bộ đóng gói ""%CurrentValue%"",
					|vì vậy, tất cả đóng gói cần đặt dưới vào mặt hàng, mà không phải vào bộ đóng gói';
					|ru = 'Для номенклатуры %Owner% выбран набор упаковок ""%CurrentValue%"",
					|поэтому все упаковки должны подчиняться номенклатуре, а не набору упаковок';
					|en = 'The ""%CurrentValue%"" packaging group is selected for the %Owner% items 
					|so all packaging units must be subordinate to the items, not the packaging group'; fa = 'The ""%CurrentValue%"" packaging group is selected for the %Owner% items 
					|so all packaging units must be subordinate to the items, not the packaging group';
					|it = 'Per l''articolo %Owner% è stato selezionato il kit di imballaggi ""%CurrentValue%"",
					| dunque tutti gli imballaggi devno essere conformi all''articolo, non al kit di imballaggio.';
					|pl = 'Dla towaru %Owner% wybrano zestaw opakowań ""%CurrentValue%"",
					|dlatego wszystkie opakowania muszą być podporządkowane towarowi, a nie zestawowi opakowań';
					|tr = '%Owner% öğesi için ""%CurrentValue%"" paketleme grubu seçildi, 
					|bu nedenle, tüm paketleme üniteleri paketleme grubuna değil, öğeye uymalıdır'");
				MessageText = StrReplace(MessageText, "%Owner%", String(Owner));
				MessageText = StrReplace(MessageText, "%CurrentValue%", String(OwnerDetailsValues.PackagingGroup));
				
				Common.MessageToUser(MessageText, ThisObject, "Owner", , Cancel);
				
			EndIf;
			
		EndIf;
		
		ValuesOfBankingDetailsBeforeRecording = Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(Ref,
			Undefined,
			"Parent");
		
		If Not IsNew()
			And ValuesOfBankingDetailsBeforeRecording.Parent <> Parent
			And Not AdditionalProperties.Property("ParentChangeIsAllowed") Then
			
			MessageText = NStr("vi = 'Có thể thay đổi các lớp trên chỉ từ biểu mẫu phần tử.';
								|ru = 'Родителя можно менять только из формы элемента.';
								|en = 'You can change the parent item only from the item form.'; fa = 'You can change the parent item only from the item form.';
								|it = 'È possibile cambiare l''elemento padre solamente dalla forma dell''elemento';
								|pl = 'Rodzic może zostać zmieniony tylko z formularza elementu.';
								|tr = 'Üst öğe, yalnızca öğe formundan değiştirilebilir.'");
			
			Common.MessageToUser(MessageText, , , ,Cancel);
			
		EndIf;
		
		If ValueIsFilled(Parent) Then
			
			ParentDetailsValues_ = Common.ObjectAttributesValues(Parent, "MeasuredValueType, 
				|PackageType");
			
			If ParentDetailsValues_.MeasuredValueType <> Enums.TypesOfMeasuredValues.Package Then
				
				MessageText = NStr("vi = 'Không thể đặt đóng gói dưới vào đơn vị tính';
									|ru = 'Нельзя подчинять упаковки единицам измерения';
									|en = 'Packaging units cannot be subordinate to a unit of measure.'; fa = 'Packaging units cannot be subordinate to a unit of measure.';
									|it = 'Gli imballaggi non devono essere subordinati alle unità di misura';
									|pl = 'Nie można podporządkować opakowania jednostkom miary';
									|tr = 'Paketleme ünitelerini ölçü birimlerine tabi kılmak imkansızdır'");
				
				Common.MessageToUser(MessageText, , , , Cancel);
				
			EndIf;
			
			If ParentDetailsValues_.PackageType = Enums.TypesOfItemsPackages.Unpacking Then
				MessageText = NStr("vi = 'Không nên đóng gói lại, dỡ gói.';
									|ru = 'Разупаковки нельзя упаковывать.';
									|en = 'No repackaging after disassembly.'; fa = 'No repackaging after disassembly.';
									|it = 'Non imballare quanto disimballato.';
									|pl = 'Rozpakowywanie nie może być pakowane.';
									|tr = 'Ambalajdan çıkarmalar paketlenemez.'");
				
				Common.MessageToUser(MessageText, , , , Cancel);
			EndIf;
			
		EndIf;
		
		If SuppliedInReusablePackage Then
			
			If PackageType = Enums.TypesOfItemsPackages.Complex
				And MinimumNumberOfReusablePackages > NumberOfPackages Then
				
				Common.MessageToUser(
					NStr("vi = 'Số lượng gói tối thiểu của bộ đóng gói dùng nhiều đợt không được vượt quá số lượng gói.';
						|ru = 'Минимальное количество упаковок многооборотной тары не может быть больше количества упаковок.';
						|en = 'The minimum number of reusable packaging units cannot exceed the total number of packaging units.'; fa = 'The minimum number of reusable packaging units cannot exceed the total number of packaging units.';
						|it = 'Il numero minimo di imballaggi riutilizzabili non può essere superiore al numero complessivo di imballaggi.';
						|pl = 'Minimalna ilość opakowań tary wielokrotnego użytku nie może być większa od ilości opakowań.';
						|tr = 'Yeniden kullanılabilir ambalajların minimum paketleme ünite sayısı, paketleme ünitesi sayısından fazla olamaz.'"),
					,
					"Object.MinimumNumberOfReusablePackages",
					,
					Cancel);
			
			ElsIf PackageType = Enums.TypesOfItemsPackages.Final
				And MinimumNumberOfReusablePackages > Numerator Then
				
				Common.MessageToUser(
					NStr("vi = 'Số lượng đóng gói tối thiểu bao bì luân chuyển không thể lớn hơn số lượng đơn vị tính 
						|theo bảng mã hiệu.';
						|ru = 'Минимальное количество упаковок многооборотной тары не может быть больше количества единиц измерения 
						|по классификатору.';
						|en = 'The minimum number of reusable packaging units cannot exceed
						|the number of units of measure in the classifier.'; fa = 'The minimum number of reusable packaging units cannot exceed
						|the number of units of measure in the classifier.';
						|it = 'Il numero minimo di imballaggi riutilizzabili non può essere superiore al numero di unità di misura
						| in base al classificatore.';
						|pl = 'Minimalna ilość opakowań tary wielokrotnego użytku nie może być większe od ilości jednostek miary 
						|wg klasyfikatora.';
						|tr = 'Yeniden kullanılabilir ambalaj paketleme ünitelerinin minimum sayısı, sınıflandırıcıya göre ölçü birimi sayısından 
						|fazla olamaz.'"),
					,
					"Object.MinimumNumberOfReusablePackages",
					,
					Cancel);
					
			EndIf;
			
		EndIf;
		
		If PackageType = Enums.TypesOfItemsPackages.Unpacking
			And Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(OwnerDetailsValues.UnitOfMeasure) Then
			
			Common.MessageToUser(
				NStr("vi = 'Sản phẩm được đo bằng một đơn vị tính - một đơn vị như vậy không thể được dỡ.';
					|ru = 'Товар измеряется в мерной единице измерения - такую единицу нельзя разупаковывать.';
					|en = 'Goods are measured in units of measure, such item cannot be repacked.'; fa = 'Goods are measured in units of measure, such item cannot be repacked.';
					|it = 'Il prodotto viene misurato in un''unità di misura - tale unità non può essere disimballata.';
					|pl = 'Towar jest mierzony w wymiarowej jednostce miary - takiej jednostki nie można rozpakowywać.';
					|tr = 'Ürünler ölçülen ölçü birimiyle ölçülür - böyle bir birim ambalajdan çıkarılamaz.'"),
				,
				"Object.PackageType",
				,
				Cancel);
			
		EndIf;
		
		If PackageType = Enums.TypesOfItemsPackages.Final Then
			NotCheckedAttributeArray.Add("Parent");
			NotCheckedAttributeArray.Add("NumberOfPackages");
			NotCheckedAttributeArray.Add("Denominator");
		ElsIf PackageType = Enums.TypesOfItemsPackages.Complex Then
			NotCheckedAttributeArray.Add("Numerator");
			NotCheckedAttributeArray.Add("Denominator");
		ElsIf PackageType = Enums.TypesOfItemsPackages.Unpacking Then
			NotCheckedAttributeArray.Add("Parent");
			NotCheckedAttributeArray.Add("NumberOfPackages");
			NotCheckedAttributeArray.Add("Numerator");
		ElsIf PackageType = Enums.TypesOfItemsPackages.CargoItem Then
			NotCheckedAttributeArray.Add("Parent");
			NotCheckedAttributeArray.Add("Numerator");
			NotCheckedAttributeArray.Add("Denominator");
		EndIf;
		
		If Not SuppliedInReusablePackage Then
			NotCheckedAttributeArray.Add("ReusablePackageItems");
			NotCheckedAttributeArray.Add("ReusablePackageVariant");
		ElsIf Not Catalogs.Products.ItemVariantsAreUsed(ReusablePackageItems) Then
			NotCheckedAttributeArray.Add("ReusablePackageVariant");
		EndIf;
		
	EndIf;
	
	CheckMultiplicityOfNumericDetails(Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If MeasuredValueType = Enums.TypesOfMeasuredValues.Package Then
		If AdditionalProperties.NeedToUpdateRepackagingOptions Then
			UpdateRepackagingOptions();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

Procedure OnReadPresentationsAtServer() Export
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region Private

Function ThereAreRepackagingOptions(ParentReference)
	
	Query = New Query;
	Query.Text =
	
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.RepackagingOptions AS RepackagingOptions
	|WHERE
	|	RepackagingOptions.Package = &Package
	|	AND NOT RepackagingOptions.Source.DeletionMark";
	
	Query.SetParameter("Package", ParentReference);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Procedure UpdateRepackagingOptions()
	
	TableOfRepackagingOptions = Catalogs.PackagesAndUnitsOfMeasure.CreateTableOfRepackagingOptionsOnServer(Owner);
	
	CompleteTableOfRepackagingOptions(TableOfRepackagingOptions);
	
	VTMaximumPackingInBranches = TableOfRepackagingOptions.Copy(,"MaximumPackageInABranch");
	VTMaximumPackingInBranches.GroupBy("MaximumPackageInABranch");
	MaximumPackingInBranches = VTMaximumPackingInBranches.UnloadColumn("MaximumPackageInABranch");
	
	For Each MaximumPackageInABranch In MaximumPackingInBranches Do
		
		Filter = New Structure("MaximumPackageInABranch", MaximumPackageInABranch);
		RepackagingOptions = TableOfRepackagingOptions.Copy(Filter);
		
		Set = InformationRegisters.RepackagingOptions.CreateRecordSet();
		Set.Filter.MaximumPackageInABranch.Set(MaximumPackageInABranch);
		Set.Load(RepackagingOptions);
		Set.Write();
		
	EndDo;
	
	// Clear the entries in the register by the maximum packages in the branch more unused.
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	RepackagingOptions.MaximumPackageInABranch AS MaximumPackageInABranch
	|FROM
	|	InformationRegister.RepackagingOptions AS RepackagingOptions
	|WHERE
	|	NOT RepackagingOptions.MaximumPackageInABranch IN (&MaximumPackageInABranch)
	|	AND RepackagingOptions.MaximumPackageInABranch.Owner = &Owner";
	Query.SetParameter("MaximumPackageInABranch", MaximumPackingInBranches);
	Query.SetParameter("Owner", Owner);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Set = InformationRegisters.RepackagingOptions.CreateRecordSet();
		Set.Filter.MaximumPackageInABranch.Set(Selection.MaximumPackageInABranch);
		Set.Clear();
		Set.Write();
	EndDo;
	
EndProcedure

// Checks whether numeric details are entered correctly. Protects against SQL error: field Overflow.
//
// Parameters:
//  Cancel	 - Boolean	 - the value is set to True if the check fails.
//
Procedure CheckMultiplicityOfNumericDetails(Cancel)
	
	MessageMultiplicityMoreThan = NStr("vi = 'Hệ số lớn hơn 10 000 000 / 1';
										|ru = 'Кратность более 10 000 000 / 1';
										|en = 'Ratio exceeds 10,000,000:1'; fa = 'Ratio exceeds 10,000,000:1';
										|it = 'Il rapporto è maggiore di 10 000 000 / 1';
										|pl = 'Współczynnik ponad 10 000 000 / 1';
										|tr = 'Çarpım faktörü 10 000 000 / 1 fazla'");
	MessageMultiplicityLessThan = NStr("vi = 'Hệ số nhỏ hơn 1 / 99 999 999';
										|ru = 'Кратность менее 1 / 99 999 999';
										|en = 'Ratio is less than 1:99,999,999'; fa = 'Ratio is less than 1:99,999,999';
										|it = 'Il rapporto è minore di 1 / 99 999 999';
										|pl = 'Współczynnik poniżej 1 / 99 999 999';
										|tr = 'Çarpım faktörü 1 / 99 999 999 az'");
	If ValueIsFilled(Denominator) Then
		If Numerator / Denominator < 0.0000001 Then
			
			Common.MessageToUser(
				MessageMultiplicityMoreThan,
				,
				"Object.Denominator",
				,
				Cancel);
			
		ElsIf Numerator / Denominator > 99999999 Then
			
			Common.MessageToUser(
				MessageMultiplicityLessThan,
				,
				"Object.Numerator",
				,
				Cancel);
			
		EndIf;
	EndIf;
	
	If MeasuredValueType = Enums.TypesOfMeasuredValues.Package
		And PackageType = Enums.TypesOfItemsPackages.CargoItem
		And ValueIsFilled(NumberOfPackages) And NumberOfPackages / 1 > 99999999 Then
		
		Common.MessageToUser(
			MessageMultiplicityLessThan,
			,
			"Object.NumberOfPackages",
			,
			Cancel);
		
	EndIf;
	
	MessageMultiplicityMoreThan = NStr("vi = 'Số nhân %PresentationOfBasicUnitOfMeasure% hơn 99.999.999 / 1';
										|ru = 'Кратность к %PresentationOfBasicUnitOfMeasure% более 99 999 999 / 1';
										|en = 'Ratio is less than 1:99,999,999. Unit: %PresentationOfBasicUnitOfMeasure%'; fa = 'Ratio is less than 1:99,999,999. Unit: %PresentationOfBasicUnitOfMeasure%';
										|it = 'Il rapporto %PresentationOfBasicUnitOfMeasure%  è maggiore di 99 999 999 / 1';
										|pl = 'Współczynnik do %PresentationOfBasicUnitOfMeasure% przekracza 99 999 999 / 1';
										|tr = 'Çarpım %PresentationOfBasicUnitOfMeasure% faktörü 99 999 999 / 1 fazla'");
	MessageMultiplicityLessThan = NStr("vi = 'Số nhân %PresentationOfBasicUnitOfMeasure% dưới 1/10 000 000';
										|ru = 'Кратность к %PresentationOfBasicUnitOfMeasure% менее 1 / 10 000 000';
										|en = 'Ratio exceeds 10,000,000:1. Unit: %PresentationOfBasicUnitOfMeasure%'; fa = 'Ratio exceeds 10,000,000:1. Unit: %PresentationOfBasicUnitOfMeasure%';
										|it = 'Il rapporto %PresentationOfBasicUnitOfMeasure%  è  minore di 1 / 10 000 000';
										|pl = 'Współczynnik do %PresentationOfBasicUnitOfMeasure% jest mniejsza od 1 / 10 000 000';
										|tr = 'Çarpım %PresentationOfBasicUnitOfMeasure% faktörü 1 / 10 000 000 az'");
	If MeasuredValueType = Enums.TypesOfMeasuredValues.Package Then
		
		If ValueIsFilled(VolumeM3) And ValueIsFilled(VolumeUnitOfMeasure) Then
			PresentationOfBasicUnitOfMeasure = NStr("vi = 'm3';
													|ru = 'м3';
													|en = 'm3'; fa = 'm3';
													|it = 'm3';
													|pl = 'm3';
													|tr = 'm3'");
			DetailsVolumeUnitOfMeasurement = Common.ObjectAttributesValues(VolumeUnitOfMeasure, "Numerator, Denominator");
			If VolumeM3 * (DetailsVolumeUnitOfMeasurement.Numerator / DetailsVolumeUnitOfMeasurement.Denominator) < 0.0000001 Then
				
				Common.MessageToUser(
					StrReplace(MessageMultiplicityLessThan, "%PresentationOfBasicUnitOfMeasure%", PresentationOfBasicUnitOfMeasure),
					,
					"Object.VolumeM3",
					,
					Cancel);
				
			ElsIf VolumeM3 * (DetailsVolumeUnitOfMeasurement.Numerator / DetailsVolumeUnitOfMeasurement.Denominator) > 99999999 Then
				
				Common.MessageToUser(
					StrReplace(MessageMultiplicityMoreThan, "%PresentationOfBasicUnitOfMeasure%", PresentationOfBasicUnitOfMeasure),
					,
					"Object.VolumeM3",
					,
					Cancel);
				
			EndIf;
		EndIf;
		
		If ValueIsFilled(Weight) And ValueIsFilled(WeightUnitOfMeasure) Then
			PresentationOfBasicUnitOfMeasure = NStr("vi = 'kg';
													|ru = 'кг';
													|en = 'kg'; fa = 'kg';
													|it = 'kg';
													|pl = 'kg';
													|tr = 'kg'");
			DetailsWeightUnitOfMeasurement = Common.ObjectAttributesValues(WeightUnitOfMeasure, "Numerator, Denominator");
			If Weight * (DetailsWeightUnitOfMeasurement.Numerator / DetailsWeightUnitOfMeasurement.Denominator) < 0.0000001 Then
				
				Common.MessageToUser(
					StrReplace(MessageMultiplicityLessThan, "%PresentationOfBasicUnitOfMeasure%", PresentationOfBasicUnitOfMeasure),
					,
					"Object.Weight",
					,
					Cancel);
				
			ElsIf Weight * (DetailsWeightUnitOfMeasurement.Numerator / DetailsWeightUnitOfMeasurement.Denominator) > 99999999 Then
				
				Common.MessageToUser(
					StrReplace(MessageMultiplicityMoreThan, "%PresentationOfBasicUnitOfMeasure%", PresentationOfBasicUnitOfMeasure),
					,
					"Object.Weight",
					,
					Cancel);
				
			EndIf;
		EndIf;
		
		If ValueIsFilled(Depth) And ValueIsFilled(DepthUnitOfMeasure) Then
			PresentationOfBasicUnitOfMeasure = NStr("vi = 'm';
													|ru = 'м';
													|en = 'm'; fa = 'متر';
													|it = 'm';
													|pl = 'm';
													|tr = 'm'");
			DetailsDepthUnitOfMeasurement = Common.ObjectAttributesValues(DepthUnitOfMeasure, "Numerator, Denominator");
			If Depth * (DetailsDepthUnitOfMeasurement.Numerator / DetailsDepthUnitOfMeasurement.Denominator) < 0.0000001 Then
				
				Common.MessageToUser(
					StrReplace(MessageMultiplicityLessThan, "%PresentationOfBasicUnitOfMeasure%", PresentationOfBasicUnitOfMeasure),
					,
					"Object.Depth",
					,
					Cancel);
				
			ElsIf Depth * (DetailsDepthUnitOfMeasurement.Numerator / DetailsDepthUnitOfMeasurement.Denominator) > 99999999 Then
				
				Common.MessageToUser(
					StrReplace(MessageMultiplicityMoreThan, "%PresentationOfBasicUnitOfMeasure%", PresentationOfBasicUnitOfMeasure),
					,
					"Object.Depth",
					,
					Cancel);
				
			EndIf;
		EndIf;
		
		If ValueIsFilled(Width) And ValueIsFilled(WidthUnitOfMeasure) Then
			PresentationOfBasicUnitOfMeasure = NStr("vi = 'm';
													|ru = 'м';
													|en = 'm'; fa = 'متر';
													|it = 'm';
													|pl = 'm';
													|tr = 'm'");
			DetailsWidthUnitOfMeasurement = Common.ObjectAttributesValues(WidthUnitOfMeasure, "Numerator, Denominator");
			If Width * (DetailsWidthUnitOfMeasurement.Numerator / DetailsWidthUnitOfMeasurement.Denominator) < 0.0000001 Then
				
				Common.MessageToUser(
					StrReplace(MessageMultiplicityLessThan, "%PresentationOfBasicUnitOfMeasure%", PresentationOfBasicUnitOfMeasure),
					,
					"Object.Width",
					,
					Cancel);
				
			ElsIf Width * (DetailsWidthUnitOfMeasurement.Numerator / DetailsWidthUnitOfMeasurement.Denominator) > 99999999 Then
				
				Common.MessageToUser(
					StrReplace(MessageMultiplicityMoreThan, "%PresentationOfBasicUnitOfMeasure%", PresentationOfBasicUnitOfMeasure),
					,
					"Object.Width",
					,
					Cancel);
				
			EndIf;
		EndIf;
		
		If ValueIsFilled(Height) And ValueIsFilled(HeightUnitOfMeasure) Then
			PresentationOfBasicUnitOfMeasure = NStr("vi = 'm';
													|ru = 'м';
													|en = 'm'; fa = 'متر';
													|it = 'm';
													|pl = 'm';
													|tr = 'm'");
			DetailsHeightUnitOfMeasurement = Common.ObjectAttributesValues(HeightUnitOfMeasure, "Numerator, Denominator");
			If Height * (DetailsHeightUnitOfMeasurement.Numerator / DetailsHeightUnitOfMeasurement.Denominator) < 0.0000001 Then
				
				Common.MessageToUser(
					StrReplace(MessageMultiplicityLessThan, "%PresentationOfBasicUnitOfMeasure%", PresentationOfBasicUnitOfMeasure),
					,
					"Object.Height",
					,
					Cancel);
				
			ElsIf Height * (DetailsHeightUnitOfMeasurement.Numerator / DetailsHeightUnitOfMeasurement.Denominator) > 99999999 Then
				
				Common.MessageToUser(
					StrReplace(MessageMultiplicityMoreThan, "%PresentationOfBasicUnitOfMeasure%", PresentationOfBasicUnitOfMeasure),
					,
					"Object.Height",
					,
					Cancel);
				
			EndIf;
		EndIf;
		
	EndIf;

	Cancel = False;
	
EndProcedure

// Supplements the table of possible repackaging options with new links:
// packages from different branches with the same parent and multiple coefficients are linked to each other.
//
// Parameters:
//  TableOfRepackagingOptions - ValueTable - a table of originally generated repackaging options.
//
Procedure CompleteTableOfRepackagingOptions(TableOfRepackagingOptions)
	
	Query = New Query;
	Query.SetParameter("DataTable", TableOfRepackagingOptions);
	Query.Text =
	"SELECT
	|	DataTable.Source AS Source,
	|	DataTable.Count AS Count,
	|	DataTable.MaximumPackageInABranch AS MaximumPackageInABranch,
	|	DataTable.Package AS Package
	|INTO TableOfRepackagingOptions
	|FROM
	|	&DataTable AS DataTable
	|WHERE
	|	DataTable.Count <> 0
	|
	|INDEX BY
	|	Source,
	|	MaximumPackageInABranch,
	|	Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ParentPackages.Source AS Source,
	|	ChildPackages.Source AS Package,
	|	ParentPackages.MaximumPackageInABranch AS MaximumPackageInABranch,
	|	ParentPackages.Count / ChildPackages.Count AS Count
	|FROM
	|	TableOfRepackagingOptions AS ParentPackages
	|		INNER JOIN TableOfRepackagingOptions AS ChildPackages
	|		ON ParentPackages.Package = ChildPackages.Package
	|		AND ParentPackages.Source <> ChildPackages.Source
	|		AND ParentPackages.Count > ChildPackages.Count
	|		AND ParentPackages.Count / ChildPackages.Count = CAST(ParentPackages.Count /
	|			ChildPackages.Count AS NUMBER(15, 0))
	|WHERE
	|	NOT (ParentPackages.Source, ChildPackages.Source, ParentPackages.MaximumPackageInABranch) IN
	|		(SELECT
	|			OriginalTableOfOptions.Source AS Source,
	|			OriginalTableOfOptions.Package AS Package,
	|			OriginalTableOfOptions.MaximumPackageInABranch AS MaximumPackageInABranch
	|		FROM
	|			TableOfRepackagingOptions AS OriginalTableOfOptions)";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		NewRow = TableOfRepackagingOptions.Add();
		FillPropertyValues(NewRow, Selection);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
#EndIf
