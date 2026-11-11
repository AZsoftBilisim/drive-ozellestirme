#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds an object creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  VisibilityCondition - Undefined, Structure - visibility condition
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands, VisibilityCondition = Undefined) Export
	
	If AccessRight("View", Metadata.DataProcessors.ReferenceAddressWarehousingOfProducts) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.DefineReferencePlacementByCells";
		CreateBasedOnCommand.Id = "DefineReferencePlacementByCells";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Sắp xếp hàng hóa theo ô hàng (tra cứu)';
												|ru = 'Размещение номенклатуры по ячейкам (справочно)';
												|en = 'Put-away — Dummy bins'; fa = 'Put-away — Dummy bins';
												|it = 'Posizionamento degli articoli per celle (come riferimento)';
												|pl = 'rozmieszczenie towarów w komórkach (informacyjnie)';
												|tr = 'Öğenin hücrelere göre yerleştirilmesi (referans olarak)'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseBinLocationWarehousingForInformation";
		If ValueIsFilled(VisibilityCondition) Then
			CreateBasedOnCommand.VisibilityConditions.Add(VisibilityCondition);
		EndIf;
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndIf