<!--
  - SPDX-FileCopyrightText: Joas Schilling <coding@schilljs.com>
  - SPDX-License-Identifier: AGPL-3.0-only
  -->
<template>
	<div class="retention-rule-card">
		<div class="retention-rule-card__header">
			<div class="retention-rule-card__tag">
				<Tag :size="20" class="retention-rule-card__tag-icon" />
				<span class="retention-rule-card__tag-name">{{ tagName }}</span>
			</div>
			<NcButton variant="tertiary"
				:aria-label="deleteLabel"
				@click="onClickDelete">
				<template #icon>
					<Delete :size="20" />
				</template>
			</NcButton>
		</div>

		<div class="retention-rule-card__body">
			<div class="retention-rule-card__detail">
				<ClockOutline :size="18" class="retention-rule-card__detail-icon" />
				<div class="retention-rule-card__detail-content">
					<span class="retention-rule-card__detail-label">{{ t('files_retention', 'Retention period') }}</span>
					<span class="retention-rule-card__detail-value">{{ getAmountAndUnit }}</span>
				</div>
			</div>

			<div class="retention-rule-card__detail">
				<Calendar :size="18" class="retention-rule-card__detail-icon" />
				<div class="retention-rule-card__detail-content">
					<span class="retention-rule-card__detail-label">{{ t('files_retention', 'Calculate from') }}</span>
					<span class="retention-rule-card__detail-value">{{ getAfter }}</span>
				</div>
			</div>

			<div class="retention-rule-card__detail">
				<FileDocument :size="18" class="retention-rule-card__detail-icon" />
				<div class="retention-rule-card__detail-content">
					<span class="retention-rule-card__detail-label">{{ t('files_retention', 'Action') }}</span>
					<span class="retention-rule-card__detail-value" :class="getActionClass">
						{{ getAction }}
						<span v-if="movetopath" class="retention-rule-card__path">
							({{ movetopath }})
						</span>
					</span>
				</div>
			</div>
		</div>
	</div>
</template>

<script>
import NcButton from '@nextcloud/vue/components/NcButton'
import Delete from 'vue-material-design-icons/TrashCanOutline.vue'
import Tag from 'vue-material-design-icons/Tag.vue'
import ClockOutline from 'vue-material-design-icons/ClockOutline.vue'
import Calendar from 'vue-material-design-icons/Calendar.vue'
import FileDocument from 'vue-material-design-icons/FileDocument.vue'

import { showSuccess } from '@nextcloud/dialogs'
import { t, n } from '@nextcloud/l10n'

export default {
	name: 'RetentionRule',

	components: {
		NcButton,
		Delete,
		Tag,
		ClockOutline,
		Calendar,
		FileDocument,
	},

	props: {
		id: {
			type: Number,
			required: true,
		},
		tagid: {
			type: Number,
			required: true,
		},
		timeunit: {
			type: Number,
			required: true,
		},
		timeamount: {
			type: Number,
			required: true,
		},
		timeafter: {
			type: Number,
			required: true,
		},
		actiontype: {
			type: Number,
			default: 0,
		},
		movetopath: {
			type: String,
			default: null,
		},
		hasJob: {
			type: Boolean,
			required: true,
		},
		tags: {
			type: Array,
			required: true,
		},
	},

	computed: {
		tagName() {
			return this.tags.find((tag) => tag.id === this.tagid)?.displayName
		},

		getAmountAndUnit() {
			switch (this.timeunit) {
			case 0:
				return n('files_retention', '%n day', '%n days', this.timeamount)
			case 1:
				return n('files_retention', '%n week', '%n weeks', this.timeamount)
			case 2:
				return n('files_retention', '%n month', '%n months', this.timeamount)
			default:
				return n('files_retention', '%n year', '%n years', this.timeamount)
			}
		},

		getAfter() {
			switch (this.timeafter) {
			case 0:
				return t('files_retention', 'Creation date')
			default:
				return t('files_retention', 'Last modification date')
			}
		},

		getAction() {
			switch (this.actiontype) {
			case 1:
				return t('files_retention', 'Move to trash')
			case 2:
				return t('files_retention', 'Move to archive')
			default:
				return t('files_retention', 'Delete permanently')
			}
		},

		getActionClass() {
			return {
				'retention-rule-card__action--delete': this.actiontype === 0,
				'retention-rule-card__action--trash': this.actiontype === 1,
				'retention-rule-card__action--archive': this.actiontype === 2,
			}
		},

		deleteLabel() {
			return t('files_retention', 'Delete retention rule for tag {tagName}', { tagName: this.tagName })
		},
	},

	methods: {
		async onClickDelete() {
			await this.$store.dispatch('deleteRetentionRule', this.id)
			showSuccess(t('files_retention', 'Retention rule for tag {tagName} has been deleted', { tagName: this.tagName }))
		},
	},
}
</script>

<style scoped lang="scss">
.retention-rule-card {
	background: var(--color-main-background);
	border: 1px solid var(--color-border);
	border-radius: var(--border-radius-large);
	padding: 16px;
	transition: box-shadow 0.2s ease;

	&:hover {
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
	}
}

.retention-rule-card__header {
	display: flex;
	justify-content: space-between;
	align-items: center;
	margin-bottom: 16px;
	padding-bottom: 12px;
	border-bottom: 1px solid var(--color-border);
}

.retention-rule-card__tag {
	display: flex;
	align-items: center;
	gap: 8px;
}

.retention-rule-card__tag-icon {
	color: var(--color-primary-element);
}

.retention-rule-card__tag-name {
	font-weight: 600;
	font-size: 1.05em;
	color: var(--color-main-text);
}

.retention-rule-card__body {
	display: flex;
	flex-direction: column;
	gap: 12px;
}

.retention-rule-card__detail {
	display: flex;
	align-items: flex-start;
	gap: 12px;
}

.retention-rule-card__detail-icon {
	flex-shrink: 0;
	margin-top: 2px;
	color: var(--color-text-maxcontrast);
}

.retention-rule-card__detail-content {
	display: flex;
	flex-direction: column;
	gap: 2px;
	flex: 1;
}

.retention-rule-card__detail-label {
	font-size: 0.85em;
	color: var(--color-text-maxcontrast);
	text-transform: uppercase;
	letter-spacing: 0.5px;
}

.retention-rule-card__detail-value {
	font-size: 0.95em;
	color: var(--color-main-text);
	font-weight: 500;
}

.retention-rule-card__action {
	&--delete {
		color: var(--color-error);
	}

	&--trash {
		color: var(--color-warning);
	}

	&--archive {
		color: var(--color-primary-element);
	}
}

.retention-rule-card__path {
	font-size: 0.9em;
	color: var(--color-text-maxcontrast);
	font-weight: normal;
}
</style>
