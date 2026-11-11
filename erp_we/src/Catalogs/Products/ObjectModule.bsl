#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		Return;
	EndIf;

	NotCheckedAttributeArray = Catalogs.Products.AttributesNotToCheck(ThisObject);
	
	// SQL error protection: Field overflow.
	CheckMultiplicityOfMeasure("Weight", Cancel);
	CheckMultiplicityOfMeasure("VolumeM3", Cancel);
	CheckMultiplicityOfMeasure("AreaTypeOfMeasurement", Cancel);
	CheckMultiplicityOfMeasure("Length", Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	ProductsLocalization.ProcessingFillInChecksProducts(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If IsNew()
		And Not ValueIsFilled(Code) Then
		
		SetNewCode();
		
	EndIf;
	
	SearchCode = ObjectsPrefixesClientServer.NumberForPrinting(Code, True);
	
	If Not TMAccessManagement.CheckWhetherCatalogDetailsCanBeChanged(ThisObject, "Description,DescriptionFull", Cancel) Then
		Return;
	EndIf;
	
	If IsFolder Then
		Return;
	EndIf;
	
	// Processing the change of details
	If Not IsNew() Then
		
		PreviousValues1 =  Common.ObjectAttributesValues(Ref, "DeletionMark, ProductKind"); 
		
		If ProductKind <> PreviousValues1.ProductKind Then
			If Not AdditionalProperties.Property("ChangingTypeOfProductHasBeenWorkedOut") Then
				Catalogs.Products.FillInDetailsForTypeOfProduct(ThisObject, True, Cancel);
			Else
				// If the check and filling have already been done, then we will simply issue warnings if something is wrong,
				// but we will not interfere with recording.
				HasError = False;
				
				Catalogs.Products.CheckCorrectnessOfChangingProductTypeFillInNewType(
					ThisObject,
					PreviousValues1.ProductKind,
					HasError);
				
				If HasError Then
					AdditionalProperties.Insert("ThereIsProblemWithChangingTypeOfProduct");
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	Catalogs.Products.WorkOutLogicOfConnectionDetails(ThisObject);

	GenerateWorkName		= Not (AdditionalProperties.Property("WorkingNameFormed"));
	GeneratePrintName	= Not (AdditionalProperties.Property("PrintNameGenerated"));
	
	If GenerateWorkName 
		Or GeneratePrintName Then
		
		AttributesStructure1 = New Structure;
		AttributesStructure1.Insert("WorkingNameTemplateOfProductItem");
		AttributesStructure1.Insert("ProhibitEditingWorkingTitleOfItems");
		AttributesStructure1.Insert("NameTemplateForPrintingOfProductItem");
		AttributesStructure1.Insert("RestrictNameChangeToPrintItems");
		
		ObjectAttributes = Common.ObjectAttributesValues(ProductKind, AttributesStructure1);
		
		If GenerateWorkName
			And ValueIsFilled(ObjectAttributes.WorkingNameTemplateOfProductItem)
			And (ObjectAttributes.ProhibitEditingWorkingTitleOfItems
				Or Not ValueIsFilled(Description)) Then
			
			DescriptionTemplate = ObjectAttributes.WorkingNameTemplateOfProductItem;
			Description = ProductsServer.NameByTemplate(DescriptionTemplate, ThisObject);
			
		EndIf;
		
		If GeneratePrintName
			And ValueIsFilled(ObjectAttributes.NameTemplateForPrintingOfProductItem)
			And (ObjectAttributes.RestrictNameChangeToPrintItems
				Or Not ValueIsFilled(DescriptionFull)) Then
			
			NameTemplateForPrinting = ObjectAttributes.NameTemplateForPrintingOfProductItem;
			DescriptionFull = ProductsServer.NameByTemplate(NameTemplateForPrinting, ThisObject);
			
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(Description) Then
		Cancel = True;
		
		ExceptionText = NStr("vi = 'Chưa điền trường ""Tên gọi làm việc""';
							|ru = 'Поле ""Рабочее наименование"" не заполнено';
							|en = '""Working title"" is required'; fa = '""Working title"" is required';
							|it = 'Il campo ""Titolo lavorativo"" non è compilato';
							|pl = 'Nie wypełniono pola ""Nazwa robocza""';
							|tr = '""Çalışma tanımı"" alanı doldurulmadı'");
		
		Raise ExceptionText;
	EndIf;
	
	MonitorWorkingName =
		Constants.ControlUniquenessOfWorkingNamesOfProductsAndItemVariants.Get()
		And Not (AdditionalProperties.Property("WorkingNameVerified"));
	
	If Not Cancel
		And MonitorWorkingName
		And Not DeletionMark Then
		
		NameUnique = Catalogs.Products.WorkingNameIsUnique(ThisObject);
		
		If Not NameUnique Then
			Cancel = True;
			
			ExceptionText = NStr("vi = 'Giá trị trường ""Tên gọi làm việc"" không đơn trị';
								|ru = 'Значение поля ""Рабочее наименование"" не уникально';
								|en = 'Value of field ""Working title"" is not unique'; fa = 'Value of field ""Working title"" is not unique';
								|it = 'Il valore del campo ""Titolo lavorativo"" non è unico';
								|pl = 'Wartość pola ""Nazwa robocza"" nie jest unikalna';
								|tr = '""Çalışma tanımı"" alanının değeri benzersiz değil'");
			
			Raise ExceptionText;
		EndIf;
		
	EndIf;
	
	AdditionalProperties.Insert("IsNew", IsNew());
	
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsFolder Then
		Return;
	EndIf;
	
	If Not Cancel
		And AdditionalProperties.Property("ThereIsProblemWithChangingTypeOfProduct") Then
		MessageText = NStr("vi = 'Phần tử đã được ghi lại, nhưng có vấn đề liên quan đến việc thay đổi dạng mặt hàng.';
							|ru = 'Запись элемента выполнена, но есть проблемы, связанные с изменением вида номенклатуры.';
							|en = 'The item is saved, but there are problems related to changing the item kind.'; fa = 'The item is saved, but there are problems related to changing the item kind.';
							|it = 'La scrittura dell''elemento è stata effettuata, ma vi sono problemi collegati al cambio del tipo della articolo.';
							|pl = 'Element został zapisany, ale istnieją problemy związane ze zmianą rodzaju towaru.';
							|tr = 'Öğenin kaydı tamamlandı, ancak öğenin türünü değiştirmekle ilgili sorunlar var.'");
		
		Common.MessageToUser(MessageText);
	EndIf;
	
	UpdateProductItemVATRates();
	MarkIndividualPackagesForRemoval();
	
	TMCommonUse.SyncKeys(ThisObject);
	AccountingForTraceableGoodsLocalization.EstablishUseOfAccountingInUnitOfMeasurementOfFEAByNomenclature(ThisObject);
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If ValueIsFilled(CopiedObject.VATRate)
		And Not VATAccountingERP.VATRateIsCorrect(
						CopiedObject.VATRate,
						Enums.VATTaxationTypes.SaleIsSubjectToVAT,
						Undefined,
						Undefined) Then
		VATRate = Catalogs.VATRates.EmptyRef();
	EndIf;

EndProcedure

#EndRegion

#Region Internal

Procedure OnReadPresentationsAtServer() Export
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
EndProcedure

#EndRegion

#Region Private

Procedure CheckMultiplicityOfMeasure(Measure, Cancel)
	DetailsOfMeasure = Catalogs.Products.DetailsOfMeasure(Measure);
	MessageMultiplicityMoreThan = NStr("vi = 'Bội số lớn hơn 10 000 000 / 1';
										|ru = 'Кратность более 10 000 000 / 1';
										|en = 'Ratio exceeds 10,000,000:1'; fa = 'Ratio exceeds 10,000,000:1';
										|it = 'Il rapporto è maggiore di 10 000 000 / 1';
										|pl = 'Współczynnik ponad 10 000 000 / 1';
										|tr = 'Çarpım faktörü 10 000 000 / 1 fazla'");
	MessageMultiplicityLessThan = NStr("vi = 'Bội số nhỏ hơn 1 / 99 999 999';
										|ru = 'Кратность менее 1 / 99 999 999';
										|en = 'Ratio is less than 1:99,999,999'; fa = 'Ratio is less than 1:99,999,999';
										|it = 'Il rapporto è minore di 1 / 99 999 999';
										|pl = 'Współczynnik poniżej 1 / 99 999 999';
										|tr = 'Çarpım faktörü 1 / 99 999 999 az'");
	If ThisObject[DetailsOfMeasure.Use]
		And ValueIsFilled(ThisObject[DetailsOfMeasure.Denominator]) Then
		If ThisObject[DetailsOfMeasure.Numerator] / ThisObject[DetailsOfMeasure.Denominator] < 0.0000001 Then
			Common.MessageToUser(
				MessageMultiplicityMoreThan,
				,
				"Object." + DetailsOfMeasure.Denominator,
				,
				Cancel);
		ElsIf ThisObject[DetailsOfMeasure.Numerator] / ThisObject[DetailsOfMeasure.Denominator] > 99999999 Then
			Common.MessageToUser(
				MessageMultiplicityLessThan,
				,
				"Object." + DetailsOfMeasure.Numerator,
				,
				Cancel);
		EndIf;
	EndIf;
EndProcedure

Function KeySynchronizationSettings()
	
	Result = New Map;
	
	Result.Insert("Catalog.InventoryLocationAttributeKeys", "DeletionMark");
	Result.Insert("Catalog.KeysOfSetAccountingDimension", "DeletionMark");
	
	Return Result;
	
EndFunction

Procedure UpdateProductItemVATRates()
	
	If Not GetFunctionalOption("UseVATAccounting") Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("IsNew")
		And AdditionalProperties.IsNew = True Then
		
		InformationRegisters.ProductsVATRates.SetCurrentVATRateOfProductForMainCountry(
			Ref,
			VATRate,
			True);
		
	ElsIf AdditionalProperties.Property("StartDateOfVATRateApplication") Then
		
		CurrentVATRate = InformationRegisters.ProductsVATRates.CurrentVATRateOfProductByMainCountry(Ref);
		StartDateOfVATRateApplication = AdditionalProperties.StartDateOfVATRateApplication;
		
		If VATRate <> CurrentVATRate Then
			
			InformationRegisters.ProductsVATRates.SetCurrentVATRateOfProductForMainCountry(
				Ref,
				VATRate,
				False,
				StartDateOfVATRateApplication);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure MarkIndividualPackagesForRemoval()
	
	If AdditionalProperties.Property("IsNew")
		And AdditionalProperties.IsNew = True Then
		
		Return;
		
	EndIf;
	
	If Not UsePackages
		Or (ValueIsFilled(PackagingGroup)
			And PackagingGroup <> Catalogs.PackagingGroups.SpecialForItem) Then
		
		SetPrivilegedMode(True);
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	ObjectData.Ref AS Ref
		|FROM
		|	Catalog.PackagesAndUnitsOfMeasure AS ObjectData
		|WHERE
		|	NOT ObjectData.DeletionMark
		|	AND ObjectData.Owner = &Owner";
		
		Query.SetParameter("Owner", Ref);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			ObjectView = Selection.Ref.GetObject(); // CatalogObject.PackagesAndUnitsOfMeasure
			ObjectView.DeletionMark = True;
			
			ObjectView.Write();
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
#EndIf
