#include "manual_mode.h"
#include "client_card.h"
#include "client_field.h"
#include "data_manager.h"
#include "deck.h"
#include "game.h"
#include "menu_handler.h"
#include "ocgapi_constants.h"
#include <IrrlichtDevice.h>
#include <IGUIButton.h>
#include <IGUIContextMenu.h>
#include <IGUIStaticText.h>
#include <IGUITabControl.h>
#include <IGUIWindow.h>
#include <algorithm>
#include <cstdint>
#include <random>

namespace ygo {

bool ManualMode::active = false;

static ClientCard* CreateManualCard(const CardDataC* data, uint8_t player, uint8_t location, uint32_t sequence) {
	auto* card = new ClientCard{};
	card->owner = player;
	card->controler = player;
	card->location = location;
	card->sequence = sequence;
	card->position = POS_FACEDOWN_DEFENSE;
	if(data) {
		card->SetCode(data->getRealCode());
		card->alias = data->alias;
		card->type = data->type;
		card->level = data->level;
		card->attribute = data->attribute;
		card->race = data->race;
		card->attack = data->attack;
		card->defense = data->defense;
		card->base_attack = data->attack;
		card->base_defense = data->defense;
		card->lscale = data->lscale;
		card->rscale = data->rscale;
		card->link_marker = data->link_marker;
	}
	return card;
}

static void RefreshCard(ClientCard* card) {
	if(!card)
		return;
	mainGame->dField.MoveCard(card, 5);
	mainGame->dField.RefreshHandHitboxes();
}

static void RestoreDefaultCommandLabels() {
	mainGame->btnActivate->setText(gDataManager->GetSysString(1150).data());
	mainGame->btnSummon->setText(gDataManager->GetSysString(1151).data());
	mainGame->btnSPSummon->setText(gDataManager->GetSysString(1152).data());
	mainGame->btnMSet->setText(gDataManager->GetSysString(1153).data());
	mainGame->btnSSet->setText(gDataManager->GetSysString(1153).data());
	mainGame->btnRepos->setText(gDataManager->GetSysString(1154).data());
	mainGame->btnAttack->setText(gDataManager->GetSysString(1157).data());
	mainGame->btnShowList->setText(gDataManager->GetSysString(1158).data());
	mainGame->btnOperation->setText(gDataManager->GetSysString(1161).data());
	mainGame->btnReset->setText(gDataManager->GetSysString(1162).data());
}
static int FindOpenSequence(uint8_t player, uint8_t location) {
	auto* list = mainGame->dField.GetList(location, player);
	if(!list)
		return -1;
	for(size_t i = 0; i < list->size(); ++i) {
		if(!(*list)[i])
			return static_cast<int>(i);
	}
	return -1;
}

static bool MoveCardTo(ClientCard* card, uint8_t location, uint32_t sequence, uint8_t position) {
	if(!card)
		return false;
	const auto previous_controler = card->controler;
	const auto previous_location = static_cast<uint8_t>(card->location);
	const auto previous_sequence = card->sequence;
	auto* moved = mainGame->dField.RemoveCard(previous_controler, previous_location, previous_sequence);
	moved->position = position;
	mainGame->dField.AddCard(moved, previous_controler, location, sequence);
	RefreshCard(moved);
	return true;
}

static ClientCard* GetCommandCard(ClientField& field) {
	if(field.command_location & (LOCATION_HAND | LOCATION_MZONE | LOCATION_SZONE))
		return field.GetCard(field.command_controler, field.command_location, field.command_sequence);
	if(field.command_location == LOCATION_DECK && !field.deck[field.command_controler].empty())
		return field.deck[field.command_controler].back();
	if(field.command_location == LOCATION_GRAVE && !field.grave[field.command_controler].empty())
		return field.grave[field.command_controler].back();
	if(field.command_location == LOCATION_REMOVED && !field.remove[field.command_controler].empty())
		return field.remove[field.command_controler].back();
	if(field.command_location == LOCATION_EXTRA && !field.extra[field.command_controler].empty())
		return field.extra[field.command_controler].back();
	return nullptr;
}

static void SetButton(irr::gui::IGUIButton* button, bool visible, const wchar_t* text, int& height) {
	button->setVisible(visible);
	if(!visible)
		return;
	button->setText(text);
	button->setRelativePosition(irr::core::vector2di(1, height));
	height += mainGame->Scale(21);
}

bool ManualMode::StartLocal() {
	if(active)
		return false;
	const auto& deck = mainGame->deckBuilder.GetCurrentDeck();
	if(deck.main.empty() && deck.extra.empty()) {
		mainGame->PopupMessage(L"Monte ou selecione um deck antes de iniciar o modo manual.");
		return false;
	}

	mainGame->ClearCardInfo();
	mainGame->mTopMenu->setVisible(false);
	mainGame->wCardImg->setVisible(true);
	mainGame->wInfos->setVisible(true);
	mainGame->wPhase->setVisible(true);
	mainGame->btnLeaveGame->setVisible(true);
	mainGame->btnLeaveGame->setText(L"Sair");
	mainGame->stHintMsg->setText(L"Modo manual: use o clique esquerdo nas cartas e pilhas.");
	mainGame->stHintMsg->setVisible(true);
	mainGame->dInfo.isInDuel = true;
	mainGame->dInfo.isStarted = true;
	mainGame->dInfo.curMsg = MSG_WAITING;
	mainGame->dField.Clear();

	for(uint8_t player = 0; player < 2; ++player) {
		for(uint32_t i = 0; i < static_cast<uint32_t>(deck.main.size()); ++i) {
			auto* card = CreateManualCard(deck.main[deck.main.size() - 1 - i], player, LOCATION_DECK, i);
			mainGame->dField.AddCard(card, player, LOCATION_DECK, i);
		}
		for(uint32_t i = 0; i < static_cast<uint32_t>(deck.extra.size()); ++i) {
			auto* card = CreateManualCard(deck.extra[deck.extra.size() - 1 - i], player, LOCATION_EXTRA, i);
			mainGame->dField.AddCard(card, player, LOCATION_EXTRA, i);
		}
	}

	mainGame->dField.RefreshAllCards();
	mainGame->device->setEventReceiver(&mainGame->dField);
	active = true;
	return true;
}

void ManualMode::Stop() {
	if(!active)
		return;
	RestoreDefaultCommandLabels();
	mainGame->wCmdMenu->setVisible(false);
	mainGame->wCardSelect->setVisible(false);
	mainGame->stTip->setVisible(false);
	mainGame->stHintMsg->setVisible(false);
	mainGame->wCardImg->setVisible(false);
	mainGame->wInfos->setVisible(false);
	mainGame->wPhase->setVisible(false);
	mainGame->btnLeaveGame->setVisible(false);
	mainGame->dInfo.isInDuel = false;
	mainGame->dInfo.isStarted = false;
	mainGame->dField.Clear();
	mainGame->device->setEventReceiver(&mainGame->menuHandler);
	mainGame->mTopMenu->setVisible(true);
	active = false;
}

bool ManualMode::IsActive() {
	return active;
}

bool ManualMode::ShowContextMenu(ClientField& field, int x, int y) {
	if(!active)
		return false;
	field.command_controler = field.hovered_controler;
	field.command_location = field.hovered_location;
	field.command_sequence = field.hovered_sequence;
	field.clicked_card = GetCommandCard(field);

	const bool has_card = field.clicked_card != nullptr;
	const bool is_pile = field.command_location == LOCATION_DECK || field.command_location == LOCATION_GRAVE ||
		field.command_location == LOCATION_REMOVED || field.command_location == LOCATION_EXTRA;
	if(!has_card && !is_pile) {
		mainGame->wCmdMenu->setVisible(false);
		return true;
	}

	int height = mainGame->Scale(1);
	const bool is_deck = field.command_location == LOCATION_DECK;
	SetButton(mainGame->btnActivate, is_deck && has_card, L"Comprar", height);
	SetButton(mainGame->btnSummon, has_card && !is_deck, L"Monstro", height);
	SetButton(mainGame->btnSPSummon, has_card && field.command_location != LOCATION_HAND, L"Mao", height);
	SetButton(mainGame->btnMSet, has_card && !is_deck, L"Set M", height);
	SetButton(mainGame->btnSSet, has_card && !is_deck, L"Set S/T", height);
	SetButton(mainGame->btnRepos, has_card && !is_deck, L"Posicao", height);
	SetButton(mainGame->btnAttack, has_card && !is_deck, L"Cemiterio", height);
	SetButton(mainGame->btnShowList, is_pile || (has_card && !field.clicked_card->overlayed.empty()), L"Ver", height);
	SetButton(mainGame->btnOperation, has_card && !is_deck, L"Banir", height);
	SetButton(mainGame->btnReset, is_deck && has_card, L"Embaralhar", height);

	field.panel = mainGame->wCmdMenu;
	mainGame->wCmdMenu->setVisible(true);
	irr::core::vector2di mouse = mainGame->Resize(x, y);
	mainGame->wCmdMenu->setRelativePosition(irr::core::recti(mouse.X - mainGame->Scale(20), mouse.Y - mainGame->Scale(20) - height,
		mouse.X + mainGame->Scale(95), mouse.Y - mainGame->Scale(20)));
	return true;
}

bool ManualMode::HandleCommand(ClientField& field, int command_id) {
	if(!active)
		return false;
	mainGame->wCmdMenu->setVisible(false);
	auto* card = GetCommandCard(field);
	if(!card)
		return true;

	switch(command_id) {
	case BUTTON_CMD_ACTIVATE: {
		if(field.command_location == LOCATION_DECK)
			MoveCardTo(card, LOCATION_HAND, 0, POS_FACEUP_ATTACK);
		else
			MoveCardTo(card, LOCATION_REMOVED, 0, POS_FACEUP_ATTACK);
		break;
	}
	case BUTTON_CMD_SUMMON: {
		const int seq = FindOpenSequence(card->controler, LOCATION_MZONE);
		if(seq >= 0)
			MoveCardTo(card, LOCATION_MZONE, static_cast<uint32_t>(seq), POS_FACEUP_ATTACK);
		break;
	}
	case BUTTON_CMD_MSET: {
		const int seq = FindOpenSequence(card->controler, LOCATION_MZONE);
		if(seq >= 0)
			MoveCardTo(card, LOCATION_MZONE, static_cast<uint32_t>(seq), POS_FACEDOWN_DEFENSE);
		break;
	}
	case BUTTON_CMD_SSET: {
		const int seq = FindOpenSequence(card->controler, LOCATION_SZONE);
		if(seq >= 0)
			MoveCardTo(card, LOCATION_SZONE, static_cast<uint32_t>(seq), POS_FACEDOWN_DEFENSE);
		break;
	}
	case BUTTON_CMD_SPSUMMON:
		MoveCardTo(card, LOCATION_HAND, 0, POS_FACEUP_ATTACK);
		break;
	case BUTTON_CMD_ATTACK:
		MoveCardTo(card, LOCATION_GRAVE, 0, POS_FACEUP_ATTACK);
		break;
	case BUTTON_CMD_REPOS: {
		if(card->position & POS_FACEDOWN)
			card->position = POS_FACEUP_ATTACK;
		else if(card->position & POS_ATTACK)
			card->position = POS_FACEUP_DEFENSE;
		else
			card->position = POS_FACEDOWN_DEFENSE;
		RefreshCard(card);
		break;
	}
	case BUTTON_CMD_RESET: {
		if(field.command_location == LOCATION_DECK) {
			static std::random_device rd;
			static std::mt19937 rng(rd());
			auto& deck = field.deck[field.command_controler];
			std::shuffle(deck.begin(), deck.end(), rng);
			for(uint32_t i = 0; i < deck.size(); ++i) {
				deck[i]->sequence = i;
				RefreshCard(deck[i]);
			}
		}
		break;
	}
	case BUTTON_CMD_SHOWLIST:
		field.command_controler = card->controler;
		field.command_location = card->location;
		field.command_sequence = card->sequence;
		field.ShowPileDisplayCards(card->location, card->controler);
		break;
	default:
		break;
	}
	return true;
}

}



