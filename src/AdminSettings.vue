<!--
  - SPDX-FileCopyrightText: Joas Schilling <coding@schilljs.com>
  - SPDX-License-Identifier: AGPL-3.0-only
  -->
<template>
	<NcSettingsSection :name="t('files_retention', 'File retention & automatic deletion')"
		:doc-url="docUrl"
		:description="t('files_retention', 'Define if files tagged with a specific tag should be deleted automatically after some time. This is useful for confidential documents.')">
		
		<!-- Existing Rules -->
		<div v-if="retentionRules.length > 0" class="retention-rules-list">
			<h3 class="retention-section-title">
				{{ t('files_retention', 'Active retention rules') }}
			</h3>
			<div class="retention-rules-grid">
				<RetentionRule v-for="rule in retentionRules"
					:key="rule.id"
					:tags="tags"
					v-bind="rule" />
			</div>
		</div>

		<!-- Create New Rule Form -->
		<div class="retention-form-container">
			<h3 class="retention-section-title">
				{{ retentionRules.length > 0 ? t('files_retention', 'Create new retention rule') : t('files_retention', 'Create your first retention rule') }}
			</h3>
			
			<div class="retention-form">
				<!-- Tag Selection -->
				<div class="retention-form__field">
					<label class="retention-form__label">
						{{ t('files_retention', 'Files tagged with') }}
					</label>
					<NcSelectTags v-model="newTag"
						:disabled="loading"
						:multiple="false"
						:clearable="false"
						:options-filter="filterAvailableTagList"
						class="retention-form__input" />
					<p class="retention-form__hint">
						{{ t('files_retention', 'Select a system tag. Files with this tag will be processed according to the retention rule.') }}
					</p>
				</div>

				<!-- Retention Time -->
				<div class="retention-form__field-group">
					<div class="retention-form__field retention-form__field--time">
						<label class="retention-form__label">
							{{ t('files_retention', 'Retention period') }}
						</label>
						<div class="retention-form__time-inputs">
							<NcTextField v-model="newAmount"
								:disabled="loading"
								type="number"
								min="1"
								:label="t('files_retention', 'Amount')"
								:aria-label="amountAriaLabel"
								class="retention-form__time-amount" />
							<NcSelect v-model="newUnit"
								:disabled="loading"
								:options="unitOptions"
								:allow-empty="false"
								:clearable="false"
								track-by="id"
								label="label"
								class="retention-form__time-unit" />
						</div>
						<p class="retention-form__hint">
							{{ t('files_retention', 'How long to keep files before processing them.') }}
						</p>
					</div>

					<div class="retention-form__field">
						<label class="retention-form__label">
							{{ t('files_retention', 'Calculate from') }}
						</label>
						<NcSelect v-model="newAfter"
							:disabled="loading"
							:options="afterOptions"
							:allow-empty="false"
							:clearable="false"
							track-by="id"
							label="label"
							class="retention-form__input" />
						<p class="retention-form__hint">
							{{ t('files_retention', 'The date to use as the starting point for the retention period.') }}
						</p>
					</div>
				</div>

				<!-- Action Selection -->
				<div class="retention-form__field">
					<label class="retention-form__label">
						{{ t('files_retention', 'What to do with expired files') }}
					</label>
					<NcSelect v-model="newAction"
						:disabled="loading"
						:options="actionOptions"
						:allow-empty="false"
						:clearable="false"
						track-by="id"
						label="label"
						class="retention-form__input" />
					<div v-if="newAction?.id === 2" class="retention-form__info-box">
						<InformationOutline :size="20" class="retention-form__info-icon" />
						<p class="retention-form__info-text">
							{{ t('files_retention', 'Files will be moved to the .archive folder, which is hidden from mobile apps. You can access archived files through the web interface.') }}
						</p>
					</div>
					<div v-else-if="newAction?.id === 1" class="retention-form__info-box">
						<InformationOutline :size="20" class="retention-form__info-icon" />
						<p class="retention-form__info-text">
							{{ t('files_retention', 'Files will be moved to the trash bin, where they can be restored if needed.') }}
						</p>
					</div>
					<div v-else class="retention-form__info-box retention-form__info-box--warning">
						<AlertCircle :size="20" class="retention-form__info-icon" />
						<p class="retention-form__info-text">
							{{ t('files_retention', 'Files will be permanently deleted. This action cannot be undone.') }}
						</p>
					</div>
				</div>

				<!-- Submit Button -->
				<div class="retention-form__actions">
					<NcButton variant="primary"
						type="button"
						:disabled="loading || newTag === null || newTag < 0"
						:aria-label="createLabel"
						@click="onClickCreate">
						<template #icon>
							<Plus :size="20" />
						</template>
						{{ t('files_retention', 'Create retention rule') }}
					</NcButton>
				</div>
			</div>
		</div>

		<!-- Notification Setting -->
		<div class="retention-notification-setting">
			<NcCheckboxRadioSwitch type="switch"
				:model-value="notifyBefore"
				:loading="loadingNotifyBefore"
				@update:modelValue="onToggleNotifyBefore">
				<div class="retention-notification-setting__content">
					<strong>{{ t('files_retention', 'Notify users before deletion') }}</strong>
					<p class="retention-notification-setting__description">
						{{ t('files_retention', 'Send a notification to file owners one day before files are automatically processed.') }}
					</p>
				</div>
			</NcCheckboxRadioSwitch>
		</div>
	</NcSettingsSection>
</template>

<script>
import NcButton from '@nextcloud/vue/components/NcButton'
import NcCheckboxRadioSwitch from '@nextcloud/vue/components/NcCheckboxRadioSwitch'
import NcSelect from '@nextcloud/vue/components/NcSelect'
import NcSelectTags from '@nextcloud/vue/components/NcSelectTags'
import NcSettingsSection from '@nextcloud/vue/components/NcSettingsSection'
import NcTextField from '@nextcloud/vue/components/NcTextField'
import Plus from 'vue-material-design-icons/Plus.vue'
import InformationOutline from 'vue-material-design-icons/InformationOutline.vue'
import AlertCircle from 'vue-material-design-icons/AlertCircle.vue'

import RetentionRule from './Components/RetentionRule.vue'
import { fetchTags } from './services/api.ts'

import { showError, showSuccess, showWarning } from '@nextcloud/dialogs'
import { loadState } from '@nextcloud/initial-state'
import { t } from '@nextcloud/l10n'

export default {
	name: 'AdminSettings',

	components: {
		NcButton,
		NcCheckboxRadioSwitch,
		NcSelect,
		NcSelectTags,
		Plus,
		RetentionRule,
		NcSettingsSection,
		NcTextField,
		InformationOutline,
		AlertCircle,
	},

	data() {
		return {
			loading: true,
			loadingNotifyBefore: false,
			notifyBefore: loadState('files_retention', 'notify_before'),
			docUrl: loadState('files_retention', 'doc-url'),

			unitOptions: [
				{ id: 0, label: t('files_retention', 'Days') },
				{ id: 1, label: t('files_retention', 'Weeks') },
				{ id: 2, label: t('files_retention', 'Months') },
				{ id: 3, label: t('files_retention', 'Years') },
			],
			newUnit: {},

			afterOptions: [
				{ id: 0, label: t('files_retention', 'Creation date') },
				{ id: 1, label: t('files_retention', 'Last modification date') },
			],
			newAfter: {},

			actionOptions: [
				{ id: 0, label: t('files_retention', 'Delete permanently') },
				{ id: 1, label: t('files_retention', 'Move to trash') },
				{ id: 2, label: t('files_retention', 'Move to archive') },
			],
			newAction: {},

			newAmount: '14',

			newTag: null,
			tagOptions: [],
			filterAvailableTagList: (tag) => {
				return !this.tagIdsWithRule.includes(tag.id)
			},
			tags: [],
		}
	},

	computed: {
		retentionRules() {
			return this.$store.getters.getRetentionRules()
		},

		tagIdsWithRule() {
			return this.$store.getters.getTagIdsWithRule()
		},

		amountAriaLabel() {
			return t('files_retention', 'Number of days, weeks, months or years after which the files should be processed')
		},

		createLabel() {
			return t('files_retention', 'Create new retention rule')
		},
	},

	async mounted() {
		try {
			this.tags = await fetchTags()
			await this.$store.dispatch('loadRetentionRules')

			this.resetForm()

			this.loading = false
		} catch (e) {
			showError(t('files_retention', 'An error occurred while loading the existing retention rules'))
			console.error(e)
		}
	},

	methods: {
		t,

		onToggleNotifyBefore() {
			this.loadingNotifyBefore = true
			const newNotifyBefore = !this.notifyBefore

			OCP.AppConfig.setValue(
				'files_retention',
				'notify_before',
				newNotifyBefore ? 'yes' : 'no',
				{
					success: function() {
						if (newNotifyBefore) {
							showSuccess(t('files_retention', 'Users are now notified one day before a file or folder is being processed'))
						} else {
							showWarning(t('files_retention', 'Users are no longer notified before a file or folder is being processed'))
						}

						this.loadingNotifyBefore = false
						this.notifyBefore = newNotifyBefore
					}.bind(this),
					error: function() {
						this.loadingNotifyBefore = false
						showError(t('files_retention', 'An error occurred while changing the setting'))
					}.bind(this),
				},
			)
		},

		async onClickCreate() {
			const newTag = this.newTag?.id ?? this.newTag
			const newUnit = this.newUnit?.id ?? this.newUnit
			const newAfter = this.newAfter?.id ?? this.newAfter
			const newAction = this.newAction?.id ?? this.newAction
			const newAmount = parseInt(this.newAmount, 10)

			if (newTag === null || newTag < 0) {
				showError(t('files_retention', 'Please select a tag'))
				return
			}

			const tagName = this.tags.find((tag) => tag.id === newTag)?.displayName

			if (this.tagIdsWithRule.includes(newTag)) {
				showError(t('files_retention', 'Tag {tagName} already has a retention rule', { tagName }))
				return
			}

			if (newUnit < 0 || newUnit > 3) {
				showError(t('files_retention', 'Invalid time unit'))
				return
			}

			if (newAfter < 0 || newAfter > 1) {
				showError(t('files_retention', 'Invalid date option'))
				return
			}

			if (newAction < 0 || newAction > 2) {
				showError(t('files_retention', 'Invalid action type'))
				return
			}

			if (isNaN(newAmount) || newAmount < 1) {
				showError(t('files_retention', 'Please enter a valid retention period (at least 1)'))
				return
			}

			try {
				const ruleData = {
					tagid: newTag,
					timeamount: newAmount,
					timeunit: newUnit,
					timeafter: newAfter,
					actiontype: newAction,
				}
				if (newAction === 2) {
					ruleData.movetopath = 'archive'
				}

				await this.$store.dispatch('createNewRule', ruleData)

				showSuccess(t('files_retention', 'Retention rule for tag {tagName} has been created', { tagName }))
				this.resetForm()
			} catch (e) {
				showError(t('files_retention', 'Failed to create retention rule for tag {tagName}', { tagName }))
				console.error(e)
			}
		},

		resetForm() {
			this.newTag = null
			this.newAmount = '14'
			this.newUnit = this.unitOptions[0]
			this.newAfter = this.afterOptions[0]
			this.newAction = this.actionOptions[0]
		},
	},
}
</script>

<style scoped lang="scss">
.retention-section-title {
	font-size: 1.2em;
	font-weight: 600;
	margin: 24px 0 16px 0;
	color: var(--color-main-text);
	
	&:first-child {
		margin-top: 0;
	}
}

.retention-rules-list {
	margin-bottom: 32px;
}

.retention-rules-grid {
	display: grid;
	grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
	gap: 16px;
	margin-bottom: 8px;
}

.retention-form-container {
	background: var(--color-main-background);
	border: 1px solid var(--color-border);
	border-radius: var(--border-radius-large);
	padding: 24px;
	margin-bottom: 24px;
}

.retention-form {
	display: flex;
	flex-direction: column;
	gap: 24px;
}

.retention-form__field {
	display: flex;
	flex-direction: column;
	gap: 8px;

	&--time {
		flex: 1;
	}
}

.retention-form__field-group {
	display: grid;
	grid-template-columns: 2fr 1fr;
	gap: 16px;

	@media (max-width: 768px) {
		grid-template-columns: 1fr;
	}
}

.retention-form__label {
	font-weight: 600;
	color: var(--color-main-text);
	font-size: 0.95em;
}

.retention-form__input {
	width: 100%;
}

.retention-form__time-inputs {
	display: grid;
	grid-template-columns: 100px 1fr;
	gap: 12px;
	align-items: end;
}

.retention-form__time-amount {
	:deep(.input-field__input) {
		text-align: right;
	}
}

.retention-form__hint {
	font-size: 0.9em;
	color: var(--color-text-maxcontrast);
	margin: 0;
	line-height: 1.4;
}

.retention-form__info-box {
	display: flex;
	gap: 12px;
	align-items: flex-start;
	padding: 12px;
	background: var(--color-primary-element-light);
	border-radius: var(--border-radius);
	margin-top: 8px;

	&--warning {
		background: var(--color-warning-light);
	}
}

.retention-form__info-icon {
	flex-shrink: 0;
	margin-top: 2px;
	color: var(--color-primary-element);
}

.retention-form__info-box--warning .retention-form__info-icon {
	color: var(--color-warning);
}

.retention-form__info-text {
	margin: 0;
	font-size: 0.9em;
	color: var(--color-main-text);
	line-height: 1.5;
}

.retention-form__actions {
	display: flex;
	justify-content: flex-end;
	margin-top: 8px;
}

.retention-notification-setting {
	margin-top: 32px;
	padding-top: 24px;
	border-top: 1px solid var(--color-border);
}

.retention-notification-setting__content {
	display: flex;
	flex-direction: column;
	gap: 4px;
	margin-left: 12px;
}

.retention-notification-setting__description {
	margin: 0;
	font-size: 0.9em;
	color: var(--color-text-maxcontrast);
	line-height: 1.4;
}
</style>
