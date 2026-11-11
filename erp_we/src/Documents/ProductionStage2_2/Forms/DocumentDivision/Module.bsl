
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Query = New Query(
		"SELECT
		|	ProductionStage.Number                                          AS Number,
		|	ProductionStage.StageName                              AS StageName,
		|	ProductionStage.NumberOfPackagesPlan                         AS NumberOfPackages,
		|	ProductionStage.PackagePlan                                   AS Package,
		|	ProductionStage.ProductionLot.MainProductProducts AS Products,
		|	CASE
		|		WHEN ProductionStage.PackagePlan = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN PRESENTATION(ProductionStage.ProductionLot.MainProductProducts.UnitOfMeasure)
		|		ELSE PRESENTATION(ProductionStage.PackagePlan)
		|	END                                                           AS PackagingPresentation
		|FROM
		|	Document.ProductionStage2_2 AS ProductionStage
		|WHERE
		|	ProductionStage.Ref = &Ref");
	Query.SetParameter("Ref", Parameters.Ref);
	Selection = Query.Execute().Select();
	Selection.Next();
	
	ThisForm.Title = StrTemplate(
		NStr("vi = 'Chia công đoạn %1';
			|ru = 'Деление этапа %1';
			|en = 'Stage division %1'; fa = 'Stage division %1';
			|it = 'Divisione delle fasi %1';
			|pl = 'Dzielenie etapu %1';
			|tr = '%1 aşamasının bölünmesi'"),
		Documents.ProductionStage2_2.PresentationStage(Selection));
	
	Items.Decoration1.Title = StrTemplate(
		NStr("vi = 'Chứng từ hiện tại: %1 %2';
			|ru = 'Текущий документ: %1 %2';
			|en = 'Current document: %1 %2'; fa = 'Current document: %1 %2';
			|it = 'Documento corente: %1 %2';
			|pl = 'Bieżący dokument: %1 %2';
			|tr = 'Mevcut belge: %1 %2'"),
		Selection.NumberOfPackages,
		Selection.PackagingPresentation);
	
	Package = Selection.Package;
	Catalogs.PackagesAndUnitsOfMeasure.DisplayInformationAboutStorageUnit(Selection.Products, Items.Package);
	Items.Package.ChoiceParameters = New FixedArray(
		CommonClientServer.ValueInArray(
			New ChoiceParameter("Products", Selection.Products)));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Split(Command)
	
	ClearMessages();
	
	If NumberOfPackages = 0 Then
		CommonClient.MessageToUser(
			NStr("vi = 'Số lượng trong chứng từ mới không được điền';
				|ru = 'Не заполнено количество в новом документе';
				|en = 'Quantity in the new document is not filled in'; fa = 'Quantity in the new document is not filled in';
				|it = 'La quantità nel nuovo documento non è compilata';
				|pl = 'Nie wypełniono ilości w nowym dokumencie';
				|tr = 'Yeni belgede miktar doldurulmadı'"),,
			"NumberOfPackages");
		Return;
	EndIf;
	
	Cancel = False;
	SplitOnServer_(Cancel);
	
	If Not Cancel Then
		NotifyChanged(Parameters.Ref);
		Notify("StageDivision_", Parameters.Ref, UUID);
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SplitOnServer_(Cancel)
	
	Try
		
		Documents.ProductionStage2_2.DivideDocument(Parameters.Ref, NumberOfPackages, Package, Cancel);
		
	Except
		
		Raise StrTemplate(
			NStr("vi = 'Không thể hoàn thành hành động vì: %1';
				|ru = 'Не удалось выполнить действие по причине: %1';
				|en = 'Cannot perform the action. Reason: %1'; fa = 'Cannot perform the action. Reason: %1';
				|it = 'Non è stato possibile eseguire azione a causa di: %1';
				|pl = 'Nie udało się wykonać czynności z powodu: %1';
				|tr = 'Eylemin gerçekleştirilememe nedeni: %1'"),
			BriefErrorDescription(ErrorInfo()));
		
	EndTry;
	
EndProcedure

#EndRegion
